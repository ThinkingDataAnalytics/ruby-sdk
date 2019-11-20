module TDAnalytics

  # TD Analytics SDK 的错误
  TDAnalyticsError = Class.new(StandardError)

  # 参数不合法
  IllegalParameterError = Class.new(TDAnalyticsError)
  
  # 网络连接错误
  ConnectionError = Class.new(TDAnalyticsError)
  
  # 服务器返回错误
  ServerError = Class.new(TDAnalyticsError)


  # 默认情况下，所有异常都不会被抛出。如果希望自己处理异常，可以实现继承自 ErrorHandler 的
  # 错误处理类，并在初始化 SDK 的时候作为参数传入.
  # 例如: 
  #    class MyErrorHandler < TDAnalytics::ErrorHandler
  #      def handle(error)
  #          puts error
  #          raise error
  #      end
  #    end
  #
  #    my_error_handler = MyErrorHandler.new
  #    tracker = TDAnalytics::Tracker.new(consumer, my_error_handler)
  class ErrorHandler

    # Override #handle to customize error handling
    def handle(error)
      false
    end
  end
end