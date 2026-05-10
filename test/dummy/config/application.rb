require_relative "boot"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module RailsPrettyLoggerDummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    config.action_controller.include_all_helpers = false

    if config.respond_to?(:autoload_lib)
      config.autoload_lib(ignore: %w[assets tasks])
    else
      config.autoload_paths << Rails.root.join("lib")
    end
  end
end
