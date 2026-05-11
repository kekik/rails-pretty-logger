ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "fileutils"

require_relative "support/dummy_log"

FileUtils.mkdir_p(Rails.root.join("log"))

class ActiveSupport::TestCase
  teardown do
    Rails::Pretty::Logger.reset_configuration!
    Rails::Pretty::Logger::PrettyLogger.clear_line_index_cache!
    Rails.application.config.x.rails_pretty_logger.authenticate_with = nil
  end
end
