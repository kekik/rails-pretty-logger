ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "fileutils"

require_relative "support/dummy_log"

FileUtils.mkdir_p(Rails.root.join("log"))
