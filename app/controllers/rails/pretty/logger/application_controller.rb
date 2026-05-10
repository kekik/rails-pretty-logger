module Rails
  module Pretty
    module Logger
      class ApplicationController < ActionController::Base
        helper Rails::Pretty::Logger::ApplicationHelper
        helper Rails::Pretty::Logger::DashboardsHelper

        protect_from_forgery with: :exception

        before_action :authenticate_rails_pretty_logger

        rescue_from Rails::Pretty::Logger::PrettyLogger::InvalidLogFile, with: :invalid_log_file
        rescue_from Rails::Pretty::Logger::PrettyLogger::FileTooLarge, with: :log_file_too_large

        private

        def authenticate_rails_pretty_logger
          auth_hook = Rails::Pretty::Logger.configuration.authenticate_with || legacy_authenticate_with
          instance_exec(&auth_hook) if auth_hook.respond_to?(:call)
        end

        def ensure_writable_rails_pretty_logger
          head :forbidden if Rails::Pretty::Logger.configuration.read_only?
        end

        def invalid_log_file
          render plain: "Invalid log file", status: :bad_request
        end

        def log_file_too_large
          render plain: "Log file is too large", status: 413
        end

        def legacy_authenticate_with
          Rails.application.config.x.rails_pretty_logger.authenticate_with
        end
      end
    end
  end
end
