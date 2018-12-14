module Rails::Pretty::Logger
  module DashboardsHelper
    def check_highlight(line)
      if line.include?("[HIGHLIGHT]")
        "<div class='highlight'>#{line.delete('[HIGHLIGHT]')}</div>".html_safe
      else
        line
      end
    end

    def time_now
      Time.now.strftime("%Y-%m-%d")
    end
    def set_divider(params)
      params[:date_range].present? ? params[:date_range][:divider] : 100
    end
  end
end
