$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'thinkingdata-ruby'
require 'time'
#require 'pry'

if __FILE__ == $0
  # 替换 DEMO_APPID 为您项目的 APP ID
  DEMO_APPID = 'APPID'
  # 替换 SERVER_URL 为您项目的 URL
  SERVER_URL = 'https://sdk.tga.thinkinggame.cn'
  # 账号 ID
  DEMO_ACCOUNT_ID = 'ruby_demo_aid'
  # 访客 ID
  DEMO_DISTINCT_ID = 'ruby_demo_did'

  # (可选) 定义一个错误处理器，当出现 Error 时会调用
  class MyErrorHandler < TDAnalytics::ErrorHandler
    def handle(error)
      puts error
      raise error
    end
  end
  my_error_handler = MyErrorHandler.new

  # 定义 consumer: consumer 实现了 add、flush、close 等接口，将经过 SDK 格式化的数据以不同的方式存储或者发送到接收端
  consumer = nil
  $ARGV = 1
  case $ARGV
  when 0
    # LoggerConsumer，数据将写入本地文件(当前目录，按小时切分，前缀为 demolog)，需要配合 Logbus 上传数据到 TA 服务器
    consumer = TDAnalytics::LoggerConsumer.new '.', 'hourly', prefix: 'demolog'
  when 1
    # DebugConsumer，数据将被逐条同步的上报到 TA 服务器。出错时会返回详细的错误信息
    consumer = TDAnalytics::DebugConsumer.new(SERVER_URL, DEMO_APPID)
    # 如果不想上传到TA，只想校验数据格式，可以如下初始化
    # consumer = TDAnalytics::DebugConsumer.new(SERVER_URL, DEMO_APPID,false)
  when 2
    # BatchConsumer，数据将先存入缓冲区，达到指定条数时上报，默认为 20 条
    consumer = TDAnalytics::BatchConsumer.new(SERVER_URL, DEMO_APPID, 30)
    #设置是否压缩数据，默认gzip压缩，内网可以这样设置
    #consumer._set_compress(false)
  else
    # LoggerConsumer，数据将写入本地文件(当前目录，按天切分，前缀为 tda.log)，需要配合 Logbus 上传数据到 TA 服务器
    consumer = TDAnalytics::LoggerConsumer.new
  end

  # 创建 TA 实例, 第一个参数为任意一种 Consumer， 第二个参数可选，如果设定了会在出错时调用
  ta = TDAnalytics::Tracker.new(consumer, my_error_handler, uuid: true)

  # 定义公共属性
  super_properties = {
      super_string: 'super_string',
      super_int: 1,
      super_bool: false,
      super_date: Time.rfc2822("Thu, 26 Oct 2019 02:26:12 +0545")
  }

  # 设置公共事件属性，公共事件属性会添加到每个事件中
  ta.set_super_properties(super_properties)

  # 定义事件数据
  event = {
      # 事件名称 （必填)
      event_name: 'test_event',
      # 账号 ID （可选)
      account_id: DEMO_ACCOUNT_ID,
      # 访客 ID （可选)，账号 ID 和访客 ID 不可以都为空
      distinct_id: DEMO_DISTINCT_ID,
      # 事件时间 (可选) 如果不填，将以调用接口时的时间作为事件时间
      time: Time.now,
      # 事件 IP (可选) 当传入 IP 地址时，后台可以解析所在地
      ip: '202.38.64.1',
      # 事件属性 (可选)
      properties: {
          array: ["str1", "11", "22.22", "2020-02-11 17:02:52.415"],
          prop_date: Time.now,
          prop_double: 134.1,
          prop_string: 'hello world',
          prop_bool: true,
      },
  }

  # 上报事件
  5.times do
    ta.track(event)
    ta.clear_super_properties
  end

  # 定义用户属性数据
  user_data = {
      # 账号 ID （可选)
      account_id: DEMO_ACCOUNT_ID,
      # 访客 ID （可选)，账号 ID 和访客 ID 不可以都为空
      distinct_id: DEMO_DISTINCT_ID,
      # 用户属性
      properties: {
          array: ["str1", 11, 22.22],
          prop_date: Time.now,
          prop_double: 134.12,
          prop_string: 'hello',
          prop_int: 666,
      },
  }
  # 设置用户属性, 覆盖同名属性
  ta.user_set(user_data)

  #追加user的一个或者多个列表的属性
  user_data_arr = {
      # 账号 ID （可选)
      account_id: DEMO_ACCOUNT_ID,
      # 访客 ID （可选)，账号 ID 和访客 ID 不可以都为空
      distinct_id: DEMO_DISTINCT_ID,
      # 用户属性
      properties: {
          array: ["33", "44"],
      },
  }

  ta.user_append(user_data_arr)

  # 设置用户属性，不会覆盖已经设置的同名属性
  user_data[:properties][:prop_int_new] = 800
  ta.user_set_once(user_data)

  # 累加用户属性
  ta.user_add(distinct_id: DEMO_DISTINCT_ID, properties: {prop_int: 10, prop_double: 15.88})


  # 删除某个用户属性
  ta.user_unset(distinct_id: DEMO_DISTINCT_ID, property: [:prop_string, :prop_int])


  # 删除用户。此操作之前的事件数据不会被删除
  # ta.user_del(distinct_id: DEMO_DISTINCT_ID)

  #binding.pry

  # 退出前调用此接口
  ta.close
end

