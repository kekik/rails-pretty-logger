require_dependency "rails/pretty/logger/application_controller"

module Rails::Pretty::Logger
  class DashboardsController < ApplicationController

    def logs
      @log = PrettyLogger.new(params)
      @log_data = @log.log_data
    end

    def index
      @log_file_list = PrettyLogger.get_log_file_list
      PrettyLogger.highlight("lorem ipsum dolor sit amet")
    end

    def clear_logs
      PrettyLogger.new(params).clear_logs
      redirect_to logs_dashboards_path({log_file: params[:log_file]})
    end

  end
end
