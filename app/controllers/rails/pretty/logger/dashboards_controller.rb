require_dependency "rails/pretty/logger/application_controller"
require "rails/pretty/parse_log"

module Rails::Pretty::Logger
  class DashboardsController < ApplicationController
    before_action :set_logger, except: [:index]

    def logs
      @log_data = @log.log_data
      @split = ParseLog.new(@log_data[:paginated_logs]).splitted_logs
      unless params[:log_file].include?("log/test.log")
        respond_to do |format|
          if params["params"].present?
            if params["params"]["request"] == "200"
              format.js { render :action => "search" }
            end
          end
          format.html { @log_data = @log.log_data }
          format.json {
            render :plain => {log_data: @split}.to_json, status: 200, content_type: 'application/json'
          }
        end
      end
    end

    def index
      @log_file_list = PrettyLogger.get_log_file_list
    end

    def clear_logs
      @log.clear_logs
      redirect_to logs_dashboards_path({log_file: params[:log_file]})
    end

    private

    def dashboard_params
      params.permit( :log_file, :utf8, :_method, :authenticity_token, :format, :commit, :page, :status, :request_type, date_range: [:end, :start, :divider])
    end

    def set_logger
      @log = PrettyLogger.new(dashboard_params)
    end
  end
end
