require "rails/pretty/logger/console_formatter"
require "rails/pretty/logger/active_support_logger"

module Rails::Pretty::Logger
  
  class ConsoleLogger < ActiveSupportLogger

    def initialize(*args, **kwargs)
      super(*args, **kwargs)
      @formatter = ConsoleFormatter.new
    end
  end

end
