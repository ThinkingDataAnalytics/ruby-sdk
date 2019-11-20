require 'securerandom'
require 'thinkingdata-ruby/errors'
require 'thinkingdata-ruby/version'

module TDAnalytics
  # TDAnalytics::Tracker 是数据上报的核心类，使用此类上报事件数据和更新用户属性.
  # 创建 Tracker 类需要传入 consumer 对象，consumer 决定了如何处理格式化的数据（存储在本地日志文件还是上传到服务端).
  #
  #   ta = TDAnalytics::Tracker.new(consumer)
  #   ta.track('your_event', distinct_id: 'distinct_id_of_user')
  #
  # TDAnalytics 提供了三种 consumer 实现:
  #   LoggerConsumer: 数据写入本地文件
  #   DebugConsumer: 数据逐条、同步的发送到服务端，并返回详细的报错信息
  #   BatchConsumer: 数据批量、同步的发送到服务端
  #
  # 您也可以传入自己实现的 Consumer，只需实现以下接口:
  #   add(message): 接受 hash 类型的数据对象
  #   flush: (可选) 将缓冲区的数据发送到指定地址
  #   close: (可选) 程序退出时用户可以主动调用此接口以保证安全退出
  class Tracker

    LIB_PROPERTIES = {
      '#lib' => 'ruby',
      '#lib_version' => TDAnalytics::VERSION,
    }

    # SDK 构造函数，传入 consumer 对象
    #
    # 默认情况下，除参数不合法外，其他 Error 会被忽略，如果您希望自己处理接口调用中的 Error，可以传入自定义的 error handler.
    # ErrorHandler 的定义可以参考 thinkingdata-ruby/errors.rb
    #
    # uuid 如果为 true，每条数据都会被带上随机 UUID 作为 #uuid 属性的值上报，该值不会入库，仅仅用于后台做数据重复检测
    def initialize(consumer, error_handler=nil, uuid: false)
      @error_handler = error_handler || ErrorHandler.new
      @consumer = consumer
      @super_properties = {}
      @uuid = uuid
    end

    # 设置公共事件属性，公共事件属性是所有事件都会带上的属性. 此方法会将传入的属性与当前公共属性合并.
    # 如果希望跳过本地格式校验，可以传入值为 true 的 skip_local_check 参数
    def set_super_properties(properties, skip_local_check = false)
      unless skip_local_check || _check_properties(:track, properties)
        @error_handler.handle(IllegalParameterError.new("Invalid super properties"))
        return false
      end
      properties.each do |k, v|
        if v.is_a?(Time)
          @super_properties[k] = _format_time(v)
        else
          @super_properties[k] = v
        end
      end
    end

    # 清除公共事件属性
    def clear_super_properties
      @super_properties = {}
    end

    # 上报事件. 每个事件都包含一个事件名和 Hash 对象的时间属性. 其参数说明如下:
    #   event_name: (必须) 事件名 必须是英文字母开头，可以包含字母、数字和 _, 长度不超过 50 个字符.
    #   distinct_id: (可选) 访客 ID
    #   account_id: （可选) 账号ID distinct_id 和 account_id 不能同时为空
    #   properties: （可选) Hash 事件属性。支持四种类型的值：字符串、数值、Time、boolean
    #   time: （可选）Time 事件发生时间，如果不传默认为系统当前时间
    #   ip: (可选) 事件 IP，如果传入 IP 地址，后端可以通过 IP 地址解析事件发生地点
    #   skip_local_check: (可选) boolean 表示是否跳过本地检测
    def track(event_name:nil, distinct_id:nil, account_id:nil, properties:{}, time:nil, ip:nil, skip_local_check: false)
      begin
        _check_name event_name
        _check_id(distinct_id, account_id)
        unless skip_local_check
          _check_properties(:track, properties)
        end
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      data = {}
      data[:event_name] = event_name
      data[:distinct_id] = distinct_id if distinct_id
      data[:account_id] = account_id if account_id
      data[:time] = time if time
      data[:ip] = ip if ip
      data[:properties] = properties

      _internal_track(:track, data)
    end

    # 设置用户属性. 如果出现同名属性，则会覆盖之前的值.
    #   distinct_id: (可选) 访客 ID
    #   account_id: （可选) 账号ID distinct_id 和 account_id 不能同时为空
    #   properties: （可选) Hash 用户属性。支持四种类型的值：字符串、数值、Time、boolean
    def user_set(distinct_id:nil, account_id:nil, properties:{}, ip:nil)
      begin
        _check_id(distinct_id, account_id)
        _check_properties(:user_set, properties)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:user_set,
        distinct_id: distinct_id,
        account_id: account_id,
        properties: properties,
        ip: ip,
      )
    end

    # 设置用户属性. 如果有重名属性，则丢弃, 参数与 user_set 相同
    def user_set_once(distinct_id:nil, account_id:nil, properties:{}, ip:nil)
      begin
        _check_id(distinct_id, account_id)
        _check_properties(:user_setOnce, properties)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:user_setOnce,
        distinct_id: distinct_id,
        account_id: account_id,
        properties: properties,
        ip: ip,
      )
    end

    # 删除用户属性, property 可以传入需要删除的用户属性的 key 值，或者 key 值数组
    def user_unset(distinct_id:nil, account_id:nil, property:nil)
      properties = {}
      if property.is_a?(Array)
        property.each do |k|
          properties[k] = 0
        end
      else
        properties[property] = 0
      end

      begin
        _check_id(distinct_id, account_id)
        _check_properties(:user_unset, properties)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:user_unset,
        distinct_id: distinct_id,
        account_id: account_id,
        properties: properties,
      )
    end

    # 累加用户属性, 如果用户属性不存在，则会设置为 0，然后再累加
    #   distinct_id: (可选) 访客 ID
    #   account_id: （可选) 账号ID distinct_id 和 account_id 不能同时为空
    #   properties: （可选) Hash 数值类型的用户属性
    def user_add(distinct_id:nil, account_id:nil, properties:{})
      begin
        _check_id(distinct_id, account_id)
        _check_properties(:user_add, properties)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:user_add,
        distinct_id: distinct_id,
        account_id: account_id,
        properties: properties,
      )
    end

    # 删除用户，用户之前的事件数据不会被删除
    def user_del(distinct_id:nil, account_id:nil)
      begin
        _check_id(distinct_id, account_id)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:user_del,
        distinct_id: distinct_id,
        account_id: account_id,
      )
    end

    # 立即上报数据，对于 BatchConsumer 会触发上报
    def flush
      return true unless defined? @consumer.flush
      ret = true
      begin
        @consumer.flush
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        ret = false
      end
      ret
    end

    # 退出前调用，保证 Consumer 安全退出
    def close
      return true unless defined? @consumer.close
      ret = true
      begin
        @consumer.close
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        ret = false
      end
      ret
    end

    private

    # 出现异常的时候返回 false, 否则 true
    def _internal_track(type, properties:{}, event_name:nil, account_id:nil, distinct_id:nil, ip:nil, time:Time.now)
      if account_id == nil && distinct_id == nil
        raise IllegalParameterError.new('account id or distinct id must be provided.')
      end

      if type == :track
        raise IllegalParameterError.new('event name is empty for track') if event_name == nil
        properties = {'#zone_offset': time.utc_offset / 3600.0}.merge(LIB_PROPERTIES).merge(@super_properties).merge(properties)
      end

      # 格式化 Time 类型
      properties.each do |k, v|
       if v.is_a?(Time)
         properties[k] = _format_time(v)
       end
      end

      data = {
        '#type' => type,
        '#time' => _format_time(time),
        'properties' => properties,
      }

      data['#event_name'] = event_name if type == :track
      data['#account_id'] = account_id if account_id
      data['#distinct_id'] = distinct_id if distinct_id
      data['#ip'] = ip if ip
      data['#uuid'] =  SecureRandom.uuid if @uuid

      ret = true
      begin
        @consumer.add(data)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        ret = false
      end

      ret
    end

    # 将 Time 类型格式化为数数指定格式的字符串
    def _format_time(time)
      time.strftime("%Y-%m-%d %H:%M:%S.#{((time.to_f * 1000.0).to_i % 1000).to_s.rjust(3, "0")}")
    end

    # 属性名或者事件名检查
    def _check_name(name)
      raise IllegalParameterError.new("the name of event or property cannot be nil") if name.nil?

      unless name.instance_of?(String) || name.instance_of?(Symbol)
        raise IllegalParameterError.new("#{name} is invalid. It must be String or Symbol")
      end

      unless name =~ /^[a-zA-Z][a-zA-Z0-9_]{1,49}$/
        raise IllegalParameterError.new("#{name} is invalid. It must be string starts with letters and contains letters, numbers, and _ with max length of 50")
      end
      true
    end

    # 属性类型检查
    def _check_properties(type, properties)
      unless properties.instance_of? Hash
        return false
      end

      properties.each do |k, v|
        _check_name k
        unless v.is_a?(Integer) || v.is_a?(Float) || v.is_a?(Symbol) || v.is_a?(String) || v.is_a?(Time) || !!v == v
          raise IllegalParameterError.new("The value of properties must be type in Integer, Float, Symbol, String, and Time")
        end

        if type == :user_add
          raise IllegalParameterError.new("Property value for user add must be numbers") unless v.is_a?(Integer) || v.is_a?(Float)
        end
      end
      true
    end

    # 检查用户 ID 合法性
    def _check_id(distinct_id, account_id)
      raise IllegalParameterError.new("account id or distinct id must be provided.") if distinct_id.nil? && account_id.nil?

      unless distinct_id.nil?
        raise IllegalParameterError.new("The length of distinct id should in (0, 64]")  if distinct_id.to_s.length < 1 || distinct_id.to_s.length > 64
      end

      unless account_id.nil?
        raise IllegalParameterError.new("The length of account id should in (0, 64]")  if account_id.to_s.length < 1 || account_id.to_s.length > 64
      end
    end
  end
end
