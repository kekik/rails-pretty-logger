module Rails
  module Pretty
    module Logger
      class Engine < ::Rails::Engine
        isolate_namespace Rails::Pretty::Logger
        ActiveSupport.on_load(:action_controller) do
                        include Rails::Pretty::Logger
                    end

        config.generators do |g|
          g.test_framework :rspec
        end
      end
    end
  end
end
