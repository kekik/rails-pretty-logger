module Rails::Pretty::Logger
  module DashboardsHelper
    def check_highlight(line)
      return "<div class='highlight'>#{line.remove('[HIGHLIGHT]')}</div>".html_safe if line.include?("[HIGHLIGHT]")
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

    def check_rails_version
      Rails::VERSION::STRING[0..2].to_f < 5.2
    end

    def parse_parameters(line)
      parameters = line[line.index("Parameters:") + 12 ..line.length]
      hash = JSON.parse parameters.gsub('=>', ':') rescue nil
      if hash.nil?
        line
      else
        h = hash.reduce("<strong> Parameters: </strong> <br/> ") {|memo, (k,v)| memo += "<strong> #{k}: </strong> #{v}, "} rescue nil
        h.html_safe rescue nil
      end

    end

  end
end
