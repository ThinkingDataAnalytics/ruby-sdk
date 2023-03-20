require 'json'
require 'net/http'

module TDAnalytics
  # The data is reported one by one, and when an error occurs, the log will be printed on the console.
  class DebugConsumer

    def test

    end

    def initialize(server_url, app_id, write_data = true, device_id: nil)
      @server_uri = URI.parse(server_url)
      @server_uri.path = '/data_debug'
      @app_id = app_id
      @write_data = write_data
      @device_id = device_id
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
      @device_id.is_a?(String) ? form_data["deviceId"] = @device_id : nil

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
