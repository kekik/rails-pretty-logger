require_dependency "rails/pretty/logger/application_controller"

module Rails::Pretty::Logger
  class DashboardsController < ApplicationController

    def log_file
      @log = PrettyLogger.new( params )
    end

    def index
      @log_file_list = PrettyLogger.get_log_list
    end

  end
end
