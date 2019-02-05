module Rails::Pretty::Logger
  module DashboardsHelper
    def check_highlight(line)
      if line.include?("[HIGHLIGHT]")
        return "<div class='highlight'>#{line.delete('[HIGHLIGHT]')}</div>".html_safe
      end
      line
    end

    def time_now
      Time.now.strftime("%Y-%m-%d")
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
      if params[:log_file] == name
        "active"
      end
    end

    def is_page_active(index, params)
      if params[:page].to_i == index
        "active"
      end
    end

  end
end
