module TDAnalytics

  TDAnalyticsError = Class.new(StandardError)

  IllegalParameterError = Class.new(TDAnalyticsError)
  
  ConnectionError = Class.new(TDAnalyticsError)
  
  ServerError = Class.new(TDAnalyticsError)


  # use example:
  #
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