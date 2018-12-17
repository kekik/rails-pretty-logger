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
      if params[:date_range].blank?
        100
      elsif params[:date_range][:divider].blank?
        100
      else
        params[:date_range][:divider]
      end
    end
  end
end
