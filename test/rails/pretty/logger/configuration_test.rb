require "test_helper"

module Rails
  module Pretty
    module Logger
      class ConfigurationTest < ActiveSupport::TestCase
        test "has safe defaults" do
          configuration = Rails::Pretty::Logger.configuration

          assert_nil configuration.authenticate_with
          assert_nil configuration.log_line_parser
          assert_nil configuration.max_file_size
          assert_equal 500, configuration.tail_lines
          assert_not configuration.read_only?
        end

        test "defaults to read only in production" do
          Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
            assert Rails::Pretty::Logger::Configuration.new.read_only?
          end
        end

        test "can be configured" do
          auth_hook = -> { head :unauthorized }

          Rails::Pretty::Logger.configure do |config|
            config.authenticate_with = auth_hook
            config.log_line_parser = ->(line) { { severity: "INFO" } if line.include?("INFO") }
            config.read_only = true
            config.max_file_size = 1024
            config.tail_lines = 200
          end

          assert_same auth_hook, Rails::Pretty::Logger.configuration.authenticate_with
          assert Rails::Pretty::Logger.configuration.log_line_parser.call("INFO custom")
          assert Rails::Pretty::Logger.configuration.read_only?
          assert_equal 1024, Rails::Pretty::Logger.configuration.max_file_size
          assert_equal 200, Rails::Pretty::Logger.configuration.tail_lines
        end
      end
    end
  end
end
