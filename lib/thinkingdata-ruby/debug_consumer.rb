require 'json'
require 'net/http'

module TDAnalytics
  # DebugConsumer 逐条、同步地向服务端上报数据
  # DebugConsumer 会返回详细的报错信息，建议在集成阶段先使用 DebugConsumer 调试接口
  class DebugConsumer

    def initialize(server_url, app_id, write_data = true)
      @server_uri = URI.parse(server_url)
      @server_uri.path = '/data_debug'
      @app_id = app_id
      @write_data = write_data
    end

    def add(message)
      puts message.to_json
      headers =  {
          'TA-Integration-Type'=>'Ruby',
          'TA-Integration-Version'=>TDAnalytics::VERSION,
          'TA-Integration-Count'=>'1',
          'TA_Integration-Extra'=>'debug'
      }
      form_data = {"data" => message.to_json, "appid" => @app_id, "dryRun" => @write_data ? "0" : "1", "source" => "server"}
      begin
        response_code, response_body = request(@server_uri, form_data,headers)
      rescue => e
        raise ConnectionError.new("Could not connect to TA server, with error \"#{e.message}\".")
      end

      result = {}
      if response_code.to_i == 200
        begin
          result = JSON.parse(response_body.to_s)
        rescue JSON::JSONError
          raise ServerError.new("Could not interpret TA server response: '#{response_body}'")
        end
      end

      if result['errorLevel'] != 0
        raise ServerError.new("Could not write to TA, server responded with #{response_code} returning: '#{response_body}'")
      end
    end

    def request(uri, form_data,headers)
      request = Net::HTTP::Post.new(uri.request_uri,headers)
      request.set_form_data(form_data)

      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = uri.scheme === 'https' ? true : false
      client.open_timeout = 10
      client.continue_timeout = 10
      client.read_timeout = 10
      client.ssl_timeout = 10

      response = client.request(request)
      [response.code, response.body]
    end
  end

end
