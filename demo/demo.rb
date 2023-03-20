$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'thinkingdata-ruby'
require 'time'

if __FILE__ == $0
  DEMO_APPID = 'app id'
  SERVER_URL = 'server url'
  DEMO_ACCOUNT_ID = '123'
  DEMO_DISTINCT_ID = 'aaa'

  class MyErrorHandler < TDAnalytics::ErrorHandler
    def handle(error)
      puts error
      raise error
    end
  end
  my_error_handler = MyErrorHandler.new

  TDAnalytics::set_stringent(false)
  TDAnalytics::set_enable_log(true)

  consumer = nil
  $ARGV = 0
  case $ARGV
  when 0
    consumer = TDAnalytics::LoggerConsumer.new './log', 'hourly'
  when 1
    consumer = TDAnalytics::DebugConsumer.new(SERVER_URL, DEMO_APPID, device_id: "123456789")
    # consumer = TDAnalytics::DebugConsumer.new(SERVER_URL, DEMO_APPID,false)
  when 2
    consumer = TDAnalytics::BatchConsumer.new(SERVER_URL, DEMO_APPID, 30)
    #consumer._set_compress(false)
  else
    consumer = TDAnalytics::LoggerConsumer.new
  end

  ta = TDAnalytics::Tracker.new(consumer, my_error_handler, uuid: true)

  super_properties = {
      super_string: 'super_string',
      super_int: 1,
      super_bool: false,
      super_date: Time.rfc2822("Thu, 26 Oct 2019 02:26:12 +0545"),
      '#app_id': "123123123123123"
  }

  ta.set_super_properties(super_properties)

  properties = {
    array: ["str1", "11", Time.now, "2020-02-11 17:02:52.415"],
    prop_date: Time.now,
    prop_double: 134.1,
    prop_string: 'hello world',
    prop_bool: true,
    '#ip': '123.123.123.123',
    '#uuid': 'aaabbbccc',
  }

  ta.set_dynamic_super_properties do
    {:dynamic_time => Time.now}
  end

  ta.track(event_name: 'test_event', distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: properties)

  ta.clear_dynamic_super_properties
  ta.clear_super_properties

  ta.track(event_name: 'test_event', distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: properties)

  user_data = {
    array: ["str1", 11, 22.22],
    prop_date: Time.now,
    prop_double: 134.12,
    prop_string: 'hello',
    prop_int: 666,
  }
  ta.user_set(distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: user_data)

  user_append_data = {
    array: %w[33 44]
  }
  ta.user_append(distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: user_append_data)

  user_uniq_append_data = {
    array: %w[44 55]
  }
  ta.user_uniq_append(distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: user_uniq_append_data)

  user_set_once_data = {
    prop_int_new: 888,
  }
  ta.user_set_once(distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: user_set_once_data)

  ta.user_add(distinct_id: DEMO_DISTINCT_ID, properties: {prop_int: 10, prop_double: 15.88})

  ta.user_unset(distinct_id: DEMO_DISTINCT_ID, property: [:prop_string, :prop_int])

  ta.user_del(distinct_id: DEMO_DISTINCT_ID)

  ta.flush

  ta.close
end

