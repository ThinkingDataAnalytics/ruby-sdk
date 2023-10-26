require 'securerandom'
require 'thinkingdata-ruby/td_errors'
require 'thinkingdata-ruby/td_version'

##
# ThinkingData module
module ThinkingData
  @is_enable_log = false
  @is_stringent = false

  ##
  # Enable SDK log or not
  # @param enable [Boolean] true or false
  def self.set_enable_log(enable)
    unless [true, false].include? enable
      enable = false
    end
    @is_enable_log = enable
  end

  ##
  # Get log status
  # @return [Boolean] enable or not
  def self.get_enable_log
    @is_enable_log
  end

  ##
  # Check or not parameter
  # @param enable [Boolean] check or not
  def self.set_stringent(enable)
    unless [true, false].include? enable
      enable = false
    end
    @is_stringent = enable
  end

  ##
  # Get parameter check status of SDK
  # @return [Boolean] check or not
  def self.get_stringent
    @is_stringent
  end

  ##
  # Analytics class。 Provides the function of tracking data
  class TDAnalytics
    LIB_PROPERTIES = {
      '#lib' => 'ruby',
      '#lib_version' => ThinkingData::VERSION,
    }

    @dynamic_block = nil

    ##
    # Init function
    #   @param consumer [consumer] data consumer: TDLoggerConsumer | TDDebugConsumer | TDBatchConsumer
    #   @param error_handler [TDErrorHandler] custom error handler, process SDK error. It could be nil
    #   @param uuid [Boolean] Whether to automatically add uuid
    def initialize(consumer, error_handler = nil, uuid: false)
      @error_handler = error_handler || TDErrorHandler.new
      @consumer = consumer
      @super_properties = {}
      @uuid_enable = uuid
      TDLog.info("SDK init success.")
    end

    ##
    # Set common properties
    def set_super_properties(properties, skip_local_check = false)
      unless ThinkingData::get_stringent == false || skip_local_check || _check_properties(:track, properties)
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

    ##
    # Clear super properties
    def clear_super_properties
      @super_properties = {}
    end

    ##
    # Set dynamic super properties
    def set_dynamic_super_properties(&block)
      @dynamic_block = block
    end

    ##
    # Clear dynamic super properties
    def clear_dynamic_super_properties
      @dynamic_block = nil
    end

    ##
    # Report ordinary event
    #   event_name: (require) A string of 50 letters and digits that starts with '#' or a letter
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    #   properties: （optional) string、number、Time、boolean
    #   time: （optional）Time
    #   ip: (optional) ip
    #   first_check_id: (optional) The value cannot be null for the first event
    #   skip_local_check: (optional) check data or not
    def track(event_name: nil, distinct_id: nil, account_id: nil, properties: {}, time: nil, ip: nil,first_check_id:nil, skip_local_check: false)
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

      _internal_track(:track, event_name: event_name, distinct_id: distinct_id, account_id: account_id, properties: properties, time: time, ip: ip, first_check_id: first_check_id)
    end

    ##
    # Report overridable event
    #   event_name: (require) A string of 50 letters and digits that starts with '#' or a letter
    #   event_id: (require) string
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    #   properties: （optional) string、number、Time、boolean
    #   time: （optional）Time
    #   ip: (optional) ip
    #   skip_local_check: (optional) check data or not
    def track_overwrite(event_name: nil,event_id: nil, distinct_id: nil, account_id: nil, properties: {}, time: nil, ip: nil, skip_local_check: false)
      begin
        _check_name event_name
        _check_event_id event_id
        _check_id(distinct_id, account_id)
        unless skip_local_check
          _check_properties(:track_overwrite, properties)
        end
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:track_overwrite, event_name: event_name, event_id: event_id, distinct_id: distinct_id, account_id: account_id, properties: properties, time: time, ip: ip)
    end

    ##
    # Report updatable event
    #   event_name: (require) A string of 50 letters and digits that starts with '#' or a letter
    #   event_id: (require) string
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    #   properties: （optional) string、number、Time、boolean
    #   time: （optional）Time
    #   ip: (optional) ip
    #   skip_local_check: (optional) check data or not
    def track_update(event_name: nil,event_id: nil, distinct_id: nil, account_id: nil, properties: {}, time: nil, ip: nil, skip_local_check: false)
      begin
        _check_name event_name
        _check_event_id event_id
        _check_id(distinct_id, account_id)
        unless skip_local_check
          _check_properties(:track_update, properties)
        end
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:track_update, event_name: event_name, event_id: event_id, distinct_id: distinct_id, account_id: account_id, properties: properties, time: time, ip: ip)
    end

    ##
    # Set user properties. would overwrite existing names
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    #   properties: （optional) string、number、Time、boolean
    #   ip: (optional) ip
    def user_set(distinct_id: nil, account_id: nil, properties: {}, ip: nil)
      begin
        _check_id(distinct_id, account_id)
        _check_properties(:user_set, properties)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:user_set, distinct_id: distinct_id, account_id: account_id, properties: properties, ip: ip)
    end

    ##
    # Set user properties, If such property had been set before, this message would be neglected
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    #   properties: （optional) string、number、Time、boolean
    #   ip: (optional) ip
    def user_set_once(distinct_id: nil, account_id: nil, properties: {}, ip: nil)
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

    ##
    # To append user properties of array type
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    #   properties: （optional) string、number、Time、boolean
    def user_append(distinct_id: nil, account_id: nil, properties: {})
      begin
        _check_id(distinct_id, account_id)
        _check_properties(:user_append, properties)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:user_append,
                      distinct_id: distinct_id,
                      account_id: account_id,
                      properties: properties,
                      )
    end

    ##
    # To append user properties of array type. It filters out duplicate values
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    #   properties: （optional) string、number、Time、boolean
    def user_uniq_append(distinct_id: nil, account_id: nil, properties: {})
      begin
        _check_id(distinct_id, account_id)
        _check_properties(:user_uniq_append, properties)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        return false
      end

      _internal_track(:user_uniq_append,
                      distinct_id: distinct_id,
                      account_id: account_id,
                      properties: properties,
                      )
    end

    ##
    # Clear the user properties of users
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    #   properties: （optional) string、number、Time、boolean
    def user_unset(distinct_id: nil, account_id: nil, property: nil)
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

    ##
    # To accumulate operations against the property
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    #   properties: （optional) string、number、Time、boolean
    def user_add(distinct_id: nil, account_id: nil, properties: {})
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

    ##
    # Delete a user, This operation cannot be undone
    #   distinct_id: (optional) distinct ID
    #   account_id: (optional) account ID. distinct_id, account_id can't both be empty.
    def user_del(distinct_id: nil, account_id: nil)
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

    ##
    # Report data immediately
    def flush
      TDLog.info("SDK flush data.")
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

    ##
    # Close and exit sdk
    def close
      return true unless defined? @consumer.close
      ret = true
      begin
        @consumer.close
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        ret = false
      end

      TDLog.info("SDK close.")

      ret
    end

    private

    def _internal_track(type, properties: {}, event_name: nil, event_id:nil, account_id: nil, distinct_id: nil, ip: nil,first_check_id: nil, time: nil)
      if type == :track || type == :track_update || type == :track_overwrite
        dynamic_properties = @dynamic_block.respond_to?(:call) ? @dynamic_block.call : {}
        properties = LIB_PROPERTIES.merge(@super_properties).merge(dynamic_properties).merge(properties)
      end

      data = {
        '#type' => type,
      }

      properties.each do |k, v|
        if v.is_a?(Time)
          properties[k] = _format_time(v)
        end
      end

      _move_preset_properties([:'#ip', :"#time", :"#app_id", :"#uuid"], data, properties: properties)

      if data[:'#time'] == nil
        if time == nil
          time = Time.now
        end
        data[:'#time'] = _format_time(time)
      end

      data['properties'] = properties
      data['#event_name'] = event_name if (type == :track || type == :track_update || type == :track_overwrite)
      data['#event_id'] = event_id if (type == :track_update || type == :track_overwrite)
      data['#account_id'] = account_id if account_id
      data['#distinct_id'] = distinct_id if distinct_id
      data['#ip'] = ip if ip
      data['#first_check_id'] = first_check_id if first_check_id
      data[:'#uuid'] = SecureRandom.uuid if @uuid_enable and data[:'#uuid'] == nil

      ret = true
      begin
        @consumer.add(data)
      rescue TDAnalyticsError => e
        @error_handler.handle(e)
        ret = false
      end

      ret
    end

    def _format_time(time)
      time.strftime("%Y-%m-%d %H:%M:%S.#{((time.to_f * 1000.0).to_i % 1000).to_s.rjust(3, "0")}")
    end

    def _check_event_id(event_id)
      if ThinkingData::get_stringent == false
        return true
      end

      raise IllegalParameterError.new("the event_id or property cannot be nil") if event_id.nil?
      true
    end

    def _check_name(name)
      if ThinkingData::get_stringent == false
        return true
      end

      raise IllegalParameterError.new("the name of event or property cannot be nil") if name.nil?

      unless name.instance_of?(String) || name.instance_of?(Symbol)
        raise IllegalParameterError.new("#{name} is invalid. It must be String or Symbol")
      end
      true
    end

    def _check_properties(type, properties)
      if ThinkingData::get_stringent == false
        return true
      end

      unless properties.instance_of? Hash
        return false
      end

      properties.each do |k, v|
        _check_name k
        next if v.nil?
        unless v.is_a?(Integer) || v.is_a?(Float) || v.is_a?(Symbol) || v.is_a?(String) || v.is_a?(Time) || !!v == v || v.is_a?(Array)
          raise IllegalParameterError.new("The value of properties must be type in Integer, Float, Symbol, String, Array,and Time")
        end

        if type == :user_add
          raise IllegalParameterError.new("Property value for user add must be numbers") unless v.is_a?(Integer) || v.is_a?(Float)
        end
        if v.is_a?(Array)
          v.each_index do |i|
            if v[i].is_a?(Time)
              v[i] = _format_time(v[i])
            end
          end
        end
      end
      true
    end

    def _check_id(distinct_id, account_id)
      if ThinkingData::get_stringent == false
        return true
      end

      raise IllegalParameterError.new("account id or distinct id must be provided.") if distinct_id.nil? && account_id.nil?
    end

    def _move_preset_properties(keys, data, properties: {})
      property_keys = properties.keys
      keys.each { |k|
        if property_keys.include? k
          data[k] = properties[k]
          properties.delete(k)
        end
      }
    end
  end

  ##
  # SDK log module
  class TDLog
    def self.info(*msg)
      if ThinkingData::get_enable_log
        print("[ThinkingData][#{Time.now}] ")
        puts(msg)
      end
    end
  end
end
