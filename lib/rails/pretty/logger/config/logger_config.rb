require "rails/pretty/logger/console_logger"
require "rails/pretty/logger/active_support_logger"


module Rails
  module Pretty
    module Logger
      module Config

        class LoggerConfig < Rails::Application

          logger_file     = ActiveSupport::TaggedLogging.new(ConsoleLogger.new('log/rails-pretty.log','hourly'))
          logger_console  = ActiveSupport::TaggedLogging.new(ConsoleLogger.new(STDOUT))
          config.logger = logger_file

          Rails.logger.extend(ActiveSupportLogger.broadcast(logger_console))
        end


      end
    end
  end
end
