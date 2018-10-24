require_dependency "rails/pretty/logger/application_controller"

module Rails::Pretty::Logger
  class DashboardsController < ApplicationController

    def log_file

      @log = PrettyLogger.new("#{params[:log_file]}.log")
      @log_files = @log.get_log_list
      @log_size = @log.file_size(@log)
      @time_now = Time.now.strftime("%Y-%m-%d")
      date = params[:date_range]
      @start_date = date[:start]
      @end_date = date[:end]
      page = params[:page].to_i ||= 0

      open_page = @log.open_log_page( @log.log_file, date[:start], date[:end] )
      @log_file_line_count = (open_page.count.to_f/100).ceil
      @paginated_logs = open_page[ page * 100 .. (page * 100) + 100 ]

    end

    def index
      @log = PrettyLogger.new
      @log_files = @log.get_log_list
      @time_now = Time.now.strftime("%Y-%m-%d")
    end

  end
end
