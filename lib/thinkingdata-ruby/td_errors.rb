module ThinkingData
  ##
  # SDK error
  TDAnalyticsError = Class.new(StandardError)

  ##
  # SDK error: illegal parameter
  IllegalParameterError = Class.new(TDAnalyticsError)

  ##
  # SDK error: connection error
  ConnectionError = Class.new(TDAnalyticsError)

  ##
  # SDK error: server error
  ServerError = Class.new(TDAnalyticsError)

  ##
  # Error handler
  #
  # e.g.
  #    class MyErrorHandler < ThinkingData::ErrorHandler
  #      def handle(error)
  #          puts error
  #          raise error
  #      end
  #    end
  #
  #    my_error_handler = MyErrorHandler.new
  #    tracker = ThinkingData::TDAnalytics.new(consumer, my_error_handler)
  class TDErrorHandler
    ##
    # Override #handle to customize error handling
    def handle(error)
      false
    end
  end
end