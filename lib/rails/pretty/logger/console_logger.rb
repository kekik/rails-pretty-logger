require "rails/pretty/logger/console_formatter"
require "rails/pretty/logger/active_support_logger"

module Rails
  module Pretty
    module Logger

      class ConsoleLogger < ActiveSupportLogger

        def initialize(*args)
          super(*args)
          @formatter = ConsoleFormatter.new
        end
      end

    end
  end
end
