# frozen_string_literal: true

module Rails
  module PrettyLogger
    class Engine < ::Rails::Engine
      isolate_namespace Rails::PrettyLogger
      ActiveSupport.on_load(:action_controller) do
        include Rails::PrettyLogger
      end
    end
  end
end
