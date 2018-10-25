require_dependency "rails/pretty/logger/application_controller"

module Rails::Pretty::Logger
  class DashboardsController < ApplicationController

    def log_file
      @start_date = params[:date_range][:start]
      @end_date = params[:date_range][:end]

      @log = PrettyLogger.new("#{params[:log_file]}.log", params)
      @log_files = @log.list
      @log_file_line_count = @log.logs_count
      @paginated_logs = @log.paginated_logs
    end

    def index
      @log = PrettyLogger.new("#{params[:log_file]}.log", params)
      @log_files = PrettyLogger.get_log_list
    end

  end
end
