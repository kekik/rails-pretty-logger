module Rails
  module Pretty
    module Logger
      class Engine < ::Rails::Engine
        isolate_namespace Rails::Pretty::Logger

        initializer "rails_pretty_logger.assets" do |app|
          if app.config.respond_to?(:assets)
            stylesheets_path = root.join("app/assets/stylesheets").to_s
            app.config.assets.paths << stylesheets_path unless app.config.assets.paths.include?(stylesheets_path)

            %w[
              rails/pretty/logger/application.css
              rails/pretty/logger/dashboards.css
              rails/pretty/logger/list.css
            ].each do |asset|
              app.config.assets.precompile << asset unless app.config.assets.precompile.include?(asset)
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
