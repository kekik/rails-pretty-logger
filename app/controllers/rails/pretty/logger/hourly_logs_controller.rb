require_dependency "rails/pretty/logger/application_controller"

module Rails::Pretty::Logger
  class HourlyLogsController < ApplicationController
    PER_PAGE = 12

    before_action :set_logger, except: [:index]
    before_action :ensure_writable_rails_pretty_logger, only: [:clear_logs]

    def logs
      @log_data = tail_mode? ? @log.tail_log_data : @log.log_data
    end

    def index
      logs = PrettyLogger.get_hourly_log_file_list.values.select { |file| file[:file_size] > 0 }
      @hourly_logs_present = logs.any?
      logs = filter_logs(logs)
      logs = sort_logs(logs)

      @page = [index_params[:page].to_i, 1].max
      @total_pages = (logs.count.to_f / PER_PAGE).ceil
      @total_pages = 1 if @total_pages.zero?
      @page = @total_pages if @page > @total_pages
      @log_file_list = logs.slice((@page - 1) * PER_PAGE, PER_PAGE) || []
    end

    def clear_logs
      @log.clear_logs
      redirect_to hourly_logs_path({log_file: @log.log_file})
    end

    private

    def index_params
      params.permit(:search, :sort, :page)
    end

    def filter_logs(logs)
      return logs if index_params[:search].blank?

      query = index_params[:search].downcase
      logs.select { |file| file[:file_name].downcase.include?(query) }
    end

    def sort_logs(logs)
      logs = logs.sort_by { |file| file[:file_name] }
      index_params[:sort] == "desc" ? logs.reverse : logs
    end

    def hourly_params
      params.permit( :log_file, :mode, :utf8, :_method, :authenticity_token, :commit, :page, date_range: [:end, :start, :divider])
    end

    def set_logger
      @log = PrettyLogger.new(hourly_params)
    end

    def tail_mode?
      hourly_params[:mode] == "tail"
    end
  end
end
