require 'logger'
require 'thinkingdata-ruby/errors'

module TDAnalytics

  # dismantle the header and save it under another name
  class HeadlessLogger < Logger
    def initialize(logdev, shift_age = 0, shift_size = 1048576)
      super(nil )
      if logdev
        @logdev = HeadlessLogger::LogDevice.new(logdev, shift_age: shift_age, shift_size: shift_size)
      end
    end

    class LogDevice < ::Logger::LogDevice
      def add_log_header(file); end
    end
  end

  # write data to file, it works with LogBus
  class LoggerConsumer

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
      _reset
    end

    def add(msg)
      unless Time.now.strftime(@suffix_mode) == @current_suffix
        @logger.close
        @current_suffix = Time.now.strftime(@suffix_mode)
        _reset
      end
      @logger.info(msg.to_json)
    end
  
    def close
      @logger.close
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