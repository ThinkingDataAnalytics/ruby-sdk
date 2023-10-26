require 'logger'
require 'thinkingdata-ruby/td_errors'

module ThinkingData

  ##
  # Dismantle the header and save it under another name
  class HeadlessLogger < Logger
    def initialize(logdev, shift_age = 0, shift_size = 1048576)
      super(nil)
      if logdev
        @logdev = HeadlessLogger::LogDevice.new(logdev, shift_age: shift_age, shift_size: shift_size)
      end
    end

    class LogDevice < ::Logger::LogDevice
      def add_log_header(file); end
    end
  end

  ##
  # Write data to file, it works with LogBus
  class TDLoggerConsumer

    ##
    # Init logger consumer
    #   @param log_path: log file's path
    #   @param mode: file rotate mode
    #   @param prefix: file prefix
    def initialize(log_path='.', mode='daily', prefix:'te.log')
      case mode
      when 'hourly'
        @suffix_mode = '%Y-%m-%d-%H'
      when 'daily'
        @suffix_mode = '%Y-%m-%d'
      else
        raise IllegalParameterError.new("#{mode} is unsupported for LoggerConsumer. Replaced it by daily or hourly")
      end

      raise IllegalParameterError.new("prefix couldn't be empty") if prefix.nil? || prefix.length == 0

      @current_suffix = Time.now.strftime(@suffix_mode)
      @log_path = log_path
      @full_prefix = "#{log_path}/#{prefix}"
      TDLog.info("TDLoggerConsumer init success. LogPath: #{log_path}")
      _reset
    end

    def add(msg)
      unless Time.now.strftime(@suffix_mode) == @current_suffix
        @logger.close
        @current_suffix = Time.now.strftime(@suffix_mode)
        _reset
      end
      msg_json_str = msg.to_json
      TDLog.info("Write data to file: #{msg_json_str}")
      @logger.info(msg_json_str)
    end
  
    def close
      @logger.close
      TDLog.info("TDLoggerConsumer close.")
    end

    private

    def _reset
      Dir::mkdir(@log_path) unless Dir::exist?(@log_path)
      @logger = HeadlessLogger.new("#{@full_prefix}.#{@current_suffix}")
      @logger.level = HeadlessLogger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
    end

  end
end