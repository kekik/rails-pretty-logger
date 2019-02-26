require "rails/pretty/logger/console_logger"
require "rails/pretty/logger/active_support_logger"


module Rails
  module Pretty
    module Logger
      module Config

        class LoggerConfig < Rails::Application

          logger_file     = ActiveSupport::TaggedLogging.new(ConsoleLogger.new(Rails.root.join('log/rails-pretty.log'), 10, 9024))
          # logger_console  = ActiveSupport::TaggedLogging.new(ConsoleLogger.new(STDOUT))
          config.logger = logger_file

          # Rails.logger.extend(ActiveSupport::Logger.broadcast(logger_console))
        end


      end
    end
  end
end
