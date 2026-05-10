require "test_helper"
require "stringio"
require "rails/pretty/logger/active_support_logger"

module Rails
  module Pretty
    module Logger
      class ActiveSupportLoggerTest < ActiveSupport::TestCase
        test "broadcast writes log entries to both loggers" do
          primary_output = StringIO.new
          broadcast_output = StringIO.new
          logger = ::ActiveSupport::Logger.new(primary_output)
          broadcast_logger = ::ActiveSupport::Logger.new(broadcast_output)

          logger.extend ActiveSupportLogger.broadcast(broadcast_logger)
          logger.info("aggregation message")

          assert_includes primary_output.string, "aggregation message"
          assert_includes broadcast_output.string, "aggregation message"
        end

        test "logger_outputs_to detects logger devices" do
          output = StringIO.new
          logger = ::ActiveSupport::Logger.new(output)

          assert ActiveSupportLogger.logger_outputs_to?(logger, output)
          assert_not ActiveSupportLogger.logger_outputs_to?(logger, StringIO.new)
        end
      end
    end
  end
end
