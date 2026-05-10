module Rails::Pretty::Logger
  module DashboardsHelper
    STRUCTURED_LOG_PRIMARY_KEYS = %w[@timestamp timestamp time datetime created_at severity level log_level message msg].freeze

    def check_highlight(line)
      rails_pretty_logger_log_entry(line)
    end

    def rails_pretty_logger_log_entry(entry)
      return rails_pretty_logger_request_group(entry) if entry.is_a?(Hash)
      return rails_pretty_logger_structured_log(entry) if rails_pretty_logger_structured_payload(entry)
      return tag.div(entry.remove("[HIGHLIGHT]"), class: "log-line highlight") if entry.include?("[HIGHLIGHT]")

      if entry.include?("Parameters:")
        tag.div(parse_parameters(entry), class: "log-line log-line--parameters")
      else
        tag.div(entry, class: "log-line")
      end
    end

    def time_now
      Time.now.strftime("%Y-%m-%d")
    end

    def is_stdout?
      ENV["RAILS_LOG_TO_STDOUT"].present?
    end

    def set_divider(params)
      if params[:date_range].blank?
        100
      elsif params[:date_range][:divider].blank?
        100
      else
        params[:date_range][:divider]
      end
    end

    def is_file_active(name, params)
      "active" if params[:log_file] == name
    end

    def is_page_active(index, params)
      "active" if params[:page].to_i == index
    end

    def parse_parameters(line)
      parameters = line[line.index("Parameters:") + "Parameters:".length..]
      hash = JSON.parse(parameters.gsub("=>", ":"))
      parts = [tag.strong("Parameters:"), tag.br]
      hash.each do |key, value|
        parts << tag.strong("#{key}: ")
        parts << value.to_s
        parts << ", "
      end
      safe_join(parts)
    rescue JSON::ParserError, TypeError
      line
    end

    def rails_pretty_logger_request_group(group)
      tag.details(class: rails_pretty_logger_request_group_classes(group), open: true) do
        safe_join([
          tag.summary(rails_pretty_logger_request_summary(group), class: "log-request__summary"),
          tag.pre(group.fetch(:lines).join, class: "log-request__body")
        ])
      end
    end

    def rails_pretty_logger_request_summary(group)
      return t("rails_pretty_logger.logs.ungrouped_lines") unless group[:type] == :request

      parts = [
        tag.span(group[:method], class: "log-request__method"),
        tag.span(group[:path], class: "log-request__path")
      ]
      parts << tag.span(group[:status], class: "log-request__status") if group[:status].present?
      parts << tag.span(group[:duration], class: "log-request__duration") if group[:duration].present?

      safe_join(parts, " ")
    end

    def rails_pretty_logger_request_group_classes(group)
      classes = ["log-request"]
      classes << "log-request--error" if group[:status].to_i >= 500
      classes.join(" ")
    end

    def rails_pretty_logger_structured_log(line)
      payload = rails_pretty_logger_structured_payload(line)
      severity = rails_pretty_logger_structured_value(payload, *Rails::Pretty::Logger::PrettyLogger::STRUCTURED_SEVERITY_KEYS)
      severity ||= rails_pretty_logger_structured_nested_log_level(payload)
      timestamp = rails_pretty_logger_structured_value(payload, *Rails::Pretty::Logger::PrettyLogger::STRUCTURED_TIMESTAMP_KEYS)
      message = payload["message"] || payload["msg"] || line

      tag.div(class: rails_pretty_logger_structured_log_classes(severity)) do
        safe_join([
          tag.div(class: "structured-log__header") do
            rails_pretty_logger_structured_header(severity, timestamp, message)
          end,
          rails_pretty_logger_structured_metadata(payload)
        ].compact)
      end
    end

    def rails_pretty_logger_structured_header(severity, timestamp, message)
      parts = []
      parts << tag.span(severity, class: "structured-log__severity") if severity.present?
      parts << tag.span(timestamp, class: "structured-log__timestamp") if timestamp.present?
      parts << tag.strong(message, class: "structured-log__message")

      safe_join(parts)
    end

    def rails_pretty_logger_structured_metadata(payload)
      metadata = payload.reject { |key, _value| STRUCTURED_LOG_PRIMARY_KEYS.include?(key.to_s) }
      return if metadata.blank?

      tag.dl(class: "structured-log__metadata") do
        safe_join(metadata.flat_map do |key, value|
          [
            tag.dt(key),
            tag.dd(value.is_a?(Hash) || value.is_a?(Array) ? JSON.generate(value) : value.to_s)
          ]
        end)
      end
    end

    def rails_pretty_logger_structured_log_classes(severity)
      classes = ["structured-log"]
      classes << "structured-log--#{severity.to_s.downcase}" if severity.present?
      classes.join(" ")
    end

    def rails_pretty_logger_structured_payload(line)
      Rails::Pretty::Logger::PrettyLogger.structured_log_payload(line)
    end

    def rails_pretty_logger_structured_value(payload, *keys)
      keys.each do |key|
        return payload[key].to_s if payload[key].present?
      end

      nil
    end

    def rails_pretty_logger_structured_nested_log_level(payload)
      nested_log = payload["log"]
      return unless nested_log.respond_to?(:[])

      nested_log["level"].to_s.upcase.presence
    end

  end
end
