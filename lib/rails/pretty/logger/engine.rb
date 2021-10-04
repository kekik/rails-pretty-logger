module Rails
  module Pretty
    module Logger
      class Engine < ::Rails::Engine
        isolate_namespace Rails::Pretty::Logger
        ActiveSupport.on_load(:action_controller) do
          include Rails::Pretty::Logger
        end
        initializer "rails-pretty-logger.assets.precompile" do |app|
          app.config.assets.precompile += %w( rails/pretty/logger/application.css rails/pretty/logger/application.js)
        end
      end
    end
  end
end
