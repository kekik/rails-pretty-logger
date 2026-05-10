require "test_helper"

module Rails
  module Pretty
    module Logger
      class ConfigurationTest < ActiveSupport::TestCase
        test "has safe defaults" do
          configuration = Rails::Pretty::Logger.configuration

          assert_nil configuration.authenticate_with
          assert_nil configuration.max_file_size
          assert_not configuration.read_only?
        end

        test "can be configured" do
          auth_hook = -> { head :unauthorized }

          Rails::Pretty::Logger.configure do |config|
            config.authenticate_with = auth_hook
            config.read_only = true
            config.max_file_size = 1024
          end

          assert_same auth_hook, Rails::Pretty::Logger.configuration.authenticate_with
          assert Rails::Pretty::Logger.configuration.read_only?
          assert_equal 1024, Rails::Pretty::Logger.configuration.max_file_size
        end
      end
    end
  end
end
