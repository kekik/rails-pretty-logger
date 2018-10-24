module Rails
  module Pretty
    module Logger
      class Engine < ::Rails::Engine
        isolate_namespace Rails::Pretty::Logger
      end
    end
  end
end
