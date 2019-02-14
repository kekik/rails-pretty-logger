require "rails/pretty/logger/console_formatter"

module Rails
  module Pretty
    module Logger

      class ConsoleLogger < ActiveSupport::Logger

        def initialize(*args)
          super(*args)
          @formatter = Rails::Pretty::Logger::ConsoleFormatter.new
        end
      end

    end
  end
end
