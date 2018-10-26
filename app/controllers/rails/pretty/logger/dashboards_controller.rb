require_dependency "rails/pretty/logger/application_controller"

module Rails::Pretty::Logger
  class DashboardsController < ApplicationController

    def log_file
      @log = PrettyLogger.new("#{params[:log_file]}.log", params)
    end

    def index
      @log = PrettyLogger.new("#{params[:log_file]}.log", params)
    end

  end
end
