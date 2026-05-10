module Rails::Pretty::Logger
  module ApplicationHelper

    def modify_name(name)
      return "#{name [-13..-10]}/#{name[-9..-8]}/#{name[-7..-6]} : #{name[-4..-1]}"
    end

    def trim_name(name)
      index = name.split("/log/").last.capitalize
    end

    def rails_pretty_logger_read_only?
      Rails::Pretty::Logger.configuration.read_only?
    end

    def rails_pretty_logger_tail_mode?
      params[:mode] == "tail"
    end

    def rails_pretty_logger_request_grouping?
      params[:group] == "request"
    end

    def rails_pretty_logger_severity_options
      [["All levels", ""]] + Rails::Pretty::Logger::PrettyLogger::SEVERITIES.map { |severity| [severity, severity] }
    end

    def rails_pretty_logger_log_base_params(include_group: true)
      log_params = { log_file: params[:log_file] }
      log_params[:mode] = params[:mode] if params[:mode].present?
      log_params[:group] = params[:group] if include_group && params[:group].present?
      log_params
    end

    def rails_pretty_logger_log_filter_params(include_mode: true, include_group: true)
      log_params = { log_file: params[:log_file] }
      log_params[:mode] = params[:mode] if include_mode && params[:mode].present?
      log_params[:group] = params[:group] if include_group && params[:group].present?
      log_params[:query] = params[:query] if params[:query].present?
      log_params[:severity] = params[:severity] if params[:severity].present?
      log_params
    end

  end
end
