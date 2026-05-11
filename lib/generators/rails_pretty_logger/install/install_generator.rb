require "rails/generators"

module RailsPrettyLogger
  module Generators
    class InstallGenerator < Rails::Generators::Base
      JAVASCRIPT_MANIFEST_LINK = "//= link rails/pretty/logger/application.js".freeze

      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "rails_pretty_logger.rb", "config/initializers/rails_pretty_logger.rb"
      end

      def mount_engine
        route %(mount Rails::Pretty::Logger::Engine => "/rails-pretty-logger")
      end

      def link_javascript_asset
        manifest = "app/assets/config/manifest.js"
        manifest_path = File.join(destination_root, manifest)
        return unless File.exist?(manifest_path)
        return if File.read(manifest_path).include?(JAVASCRIPT_MANIFEST_LINK)

        separator = File.read(manifest_path).end_with?("\n") ? "" : "\n"
        append_to_file manifest, "#{separator}#{JAVASCRIPT_MANIFEST_LINK}\n"
      end
    end
  end
end
