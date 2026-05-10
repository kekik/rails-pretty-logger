module Rails
  module Pretty
    module Logger
      class ApplicationController < ActionController::Base
        helper Rails::Pretty::Logger::ApplicationHelper
        helper Rails::Pretty::Logger::DashboardsHelper

        protect_from_forgery with: :exception

        before_action :authenticate_rails_pretty_logger

        rescue_from Rails::Pretty::Logger::PrettyLogger::InvalidLogFile, with: :invalid_log_file

        private

        def authenticate_rails_pretty_logger
          auth_hook = Rails.application.config.x.rails_pretty_logger.authenticate_with
          instance_exec(&auth_hook) if auth_hook.respond_to?(:call)
        end

        def invalid_log_file
          render plain: "Invalid log file", status: :bad_request
        end
      end
    end
  end
end
