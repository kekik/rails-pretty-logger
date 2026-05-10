module Rails::Pretty::Logger
  module DashboardsHelper
    def check_highlight(line)
      return tag.div(line.remove("[HIGHLIGHT]"), class: "highlight") if line.include?("[HIGHLIGHT]")

      if line.include?("Parameters:")
        parse_parameters(line)
      else
        line
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


  end
end
