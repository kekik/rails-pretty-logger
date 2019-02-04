require_dependency "rails/pretty/logger/application_controller"

module Rails::Pretty::Logger
  class DashboardsController < ApplicationController

    def log_file
      @log = PrettyLogger.new(params)
      @log_data = @log.log_data
    end

    def index
      @log_file_list = PrettyLogger.get_log_file_list
      PrettyLogger.highlight("lorem ipsum dolor sit amet")
    end

  end
end
