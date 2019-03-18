require_dependency "rails/pretty/logger/application_controller"

module Rails::Pretty::Logger
  class HourlyLogsController < ApplicationController
    before_action :set_logger, except: [:index]

    def logs
      @log_data = @log.log_data
    end

    def index
      @log_file_list = PrettyLogger.get_hourly_log_file_list
    end

    def clear_logs
      @log.clear_logs
      redirect_to logs_dashboards_path({log_file: params[:log_file]})
    end

    private

    def hourly_params
      params.permit( :log_file, :utf8, :authenticity_token, :commit, date_range: [:end, :start, :divider])
    end

    def set_logger
      @log = PrettyLogger.new(hourly_params)
    end

  end
end
