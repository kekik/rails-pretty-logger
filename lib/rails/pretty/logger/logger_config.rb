require "rails/pretty/logger/console_logger"


module Rails
  module Pretty
    module Logger

      class LoggerConfig < Rails::Application
        logger_file     = ActiveSupport::TaggedLogging.new(ConsoleLogger.new(Rails.root.join('log/rails-pretty2.log'), 10, 10240))
        logger_console  = ActiveSupport::TaggedLogging.new(ConsoleLogger.new(STDOUT))
        config.logger = logger_file

        Rails.logger.extend(ActiveSupport::Logger.broadcast(logger_console))
      end


    end
  end
end
