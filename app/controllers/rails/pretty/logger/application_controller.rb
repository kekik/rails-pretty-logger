module Rails
  module Pretty
    module Logger
      class ApplicationController < ActionController::Base
        helper Rails::Pretty::Logger::ApplicationHelper
        helper Rails::Pretty::Logger::DashboardsHelper

        protect_from_forgery with: :exception
      end
    end
  end
end
