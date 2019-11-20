require 'logger'
require 'thinkingdata-ruby/errors'

module TDAnalytics
  # 将数据写入本地文件, 需配合 LogBus 将数据上传到服务器
  # 由于 LogBus 有完善的失败重传机制，因此建议用户首先考虑此方案
  class LoggerConsumer
    # LoggerConsumer 构造函数
    #   log_path: 日志文件存放目录
    #   mode: 日志文件切分模式，可选 daily/hourly
    #   prefix: 日志文件前缀，默认为 'tda.log', 日志文件名格式为: tda.log.2019-11-15
    def initialize(log_path='.', mode='daily', prefix:'tda.log')
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

      @full_prefix = "#{log_path}/#{prefix}."

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
  
    # 关闭 logger
    def close
      @logger.close
    end

    private

    # 重新创建 logger 对象. LogBus 判断新文件会同时考虑文件名和 inode，因此默认的切分方式会导致数据重传
    def _reset
      @logger = Logger.new("#{@full_prefix}#{@current_suffix}")
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
    end

  end
end