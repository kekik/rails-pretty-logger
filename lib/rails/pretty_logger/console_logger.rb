# frozen_string_literal: true

require_relative './console_formatter'
require_relative './active_support_logger'

module Rails
  module PrettyLogger
    class ConsoleLogger < ActiveSupportLogger
      def initialize(*args)
        super(*args)
        @formatter = ConsoleFormatter.new
      end
    end
  end
end
