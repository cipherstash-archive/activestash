module ActiveStash
  class Logger
    class << self
      def debug(message)
        instance.debug(message)
      end

      def info(message)
        instance.info(message)
      end

      def warn(message)
        instance.warn(message)
      end

      def error(message)
        instance.error(message)
      end

      def instance
        return @logger if @logger

        if defined?(Rails)
          @logger = Rails.logger
        else
          @logger = Logger.new(STDOUT)
        end
      end
    end
  end
end
