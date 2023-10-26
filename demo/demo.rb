$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'thinkingdata-ruby'
require 'time'

if __FILE__ == $0

  class MyErrorHandler < ThinkingData::TDErrorHandler
    def handle(error)
      puts error
      raise error
    end
  end

  def logger_consumer
    ThinkingData::TDLoggerConsumer.new('./log', 'hourly')
  end

  def debug_consumer
    ThinkingData::TDDebugConsumer.new("serverUrl", "appId", device_id: "123456789")
  end

  def batch_consumer
    consumer = ThinkingData::TDBatchConsumer.new("serverUrl", "appId", 50)
    consumer._set_compress(false)
    consumer
  end

  ThinkingData::set_stringent(false)
  ThinkingData::set_enable_log(true)
  my_error_handler = MyErrorHandler.new

  td_sdk = ThinkingData::TDAnalytics.new(logger_consumer, my_error_handler, uuid: false)
  # td_sdk = ThinkingData::TDAnalytics.new(debug_consumer, my_error_handler, uuid: true)
  # td_sdk = ThinkingData::TDAnalytics.new(batch_consumer, my_error_handler, uuid: true)

  DEMO_ACCOUNT_ID = '123'
  DEMO_DISTINCT_ID = 'aaa'

  super_properties = {
      super_string: 'super_string',
      super_int: 1,
      super_bool: false,
      super_date: Time.rfc2822("Thu, 26 Oct 2019 02:26:12 +0545"),
      '#app_id': "123123123123123"
  }

  td_sdk.set_super_properties(super_properties)

  properties = {
    array: ["str1", "11", Time.now, "2020-02-11 17:02:52.415"],
    prop_date: Time.now,
    prop_double: 134.1,
    prop_string: 'hello world',
    prop_bool: true,
    '#ip': '123.123.123.123',
  }

  td_sdk.set_dynamic_super_properties do
    {:dynamic_time => Time.now}
  end

  td_sdk.track(event_name: 'test_event', distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: properties)

  td_sdk.clear_dynamic_super_properties
  td_sdk.clear_super_properties

  td_sdk.track(event_name: 'test_event', distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: properties)

  user_data = {
    array: ["str1", 11, 22.22],
    prop_date: Time.now,
    prop_double: 134.12,
    prop_string: 'hello',
    prop_int: 666,
  }
  td_sdk.user_set(distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: user_data)

  user_append_data = {
    array: %w[33 44]
  }
  td_sdk.user_append(distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: user_append_data)

  user_uniq_append_data = {
    array: %w[44 55]
  }
  td_sdk.user_uniq_append(distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: user_uniq_append_data)

  user_set_once_data = {
    prop_int_new: 888,
  }
  td_sdk.user_set_once(distinct_id: DEMO_DISTINCT_ID, account_id: DEMO_ACCOUNT_ID, properties: user_set_once_data)

  td_sdk.user_add(distinct_id: DEMO_DISTINCT_ID, properties: {prop_int: 10, prop_double: 15.88})

  td_sdk.user_unset(distinct_id: DEMO_DISTINCT_ID, property: [:prop_string, :prop_int])

  td_sdk.user_del(distinct_id: DEMO_DISTINCT_ID)

  td_sdk.flush

  td_sdk.close
end

