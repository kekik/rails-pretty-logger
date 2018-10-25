module Rails
  module Pretty
    module Logger
      class Engine < ::Rails::Engine
        isolate_namespace Rails::Pretty::Logger


        config.generators do |g|
          g.test_framework :rspec
        end
      end
    end
  end
end
