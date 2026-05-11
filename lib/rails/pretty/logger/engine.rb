module Rails
  module Pretty
    module Logger
      class Engine < ::Rails::Engine
        isolate_namespace Rails::Pretty::Logger

        initializer "rails_pretty_logger.assets" do |app|
          assets_config = app.config.assets if app.config.respond_to?(:assets)

          if assets_config.respond_to?(:paths) && assets_config.respond_to?(:precompile)
            %w[stylesheets javascripts].each do |asset_path|
              path = root.join("app/assets", asset_path).to_s
              assets_config.paths << path unless assets_config.paths.include?(path)
            end

            %w[
              rails/pretty/logger/application.js
              rails/pretty/logger/application.css
              rails/pretty/logger/dashboards.css
              rails/pretty/logger/list.css
            ].each do |asset|
              assets_config.precompile << asset unless assets_config.precompile.include?(asset)
            end
          end
        end

        rake_tasks do
          load root.join("lib/tasks/rails/pretty/logger_tasks.rake")
        end
      end
    end
  end
end
