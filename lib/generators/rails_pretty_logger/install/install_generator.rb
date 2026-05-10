require "rails/generators"

module RailsPrettyLogger
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "rails_pretty_logger.rb", "config/initializers/rails_pretty_logger.rb"
      end

      def mount_engine
        route %(mount Rails::Pretty::Logger::Engine => "/rails-pretty-logger")
      end
    end
  end
end
