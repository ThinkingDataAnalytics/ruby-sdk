require 'base64'
require 'json'
require 'net/http'

module TDAnalytics
  # BatchConsumer 批量同步的发送数据.
  # 有数据时，首先会加入本地缓冲区，当条数到达上限后会发起上报
  class BatchConsumer
    # 默认缓冲区大小
    MAX_LENGTH = 20

    def initialize(server_url, app_id, max_buffer_length=MAX_LENGTH)
      @server_uri = URI.parse(server_url)
      @server_uri.path = '/logagent'
      @app_id = app_id
      @max_length = [max_buffer_length, MAX_LENGTH].min
      @buffers = []
    end

    def add(message)
      @buffers << message
      flush if @buffers.length >= @max_length
    end

    def close
      flush
    end

    def flush
      begin
        @buffers.each_slice(@max_length) do |chunk|
          wio = StringIO.new("w")
          gzip_io = Zlib::GzipWriter.new(wio)
          gzip_io.write(chunk.to_json)
          gzip_io.close
          data = Base64.encode64(wio.string).gsub("\n", '')

          headers = {'Content-Type' => 'application/plaintext', 'appid' => @app_id}
          request = CaseSensitivePost.new(@server_uri.request_uri, headers)
          request.body = data

          begin
            response_code, response_body = _request(@server_uri, request)
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
    
          if result['code'] != 0
            raise ServerError.new("Could not write to TA, server responded with #{response_code} returning: '#{response_body}'")
          end
        end
      rescue
        raise
      end
      @buffers = []
    end

    private
    def _request(uri, request)
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

  # 内部使用，为了兼容老版本服务端，将 Header 名称限定为小写
  class CaseSensitivePost < Net::HTTP::Post
    def initialize_http_header(headers)
      @header = {}
      headers.each{|k,v| @header[k.to_s] = [v] }
    end
  
    def [](name)
      @header[name.to_s]
    end
  
    def []=(name, val)
      if val
        @header[name.to_s] = [val]
      else
        @header.delete(name.to_s)
      end
    end
  
    def capitalize(name)
      name
    end
  end

end
