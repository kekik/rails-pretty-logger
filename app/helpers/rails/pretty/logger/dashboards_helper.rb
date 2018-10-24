module Rails::Pretty::Logger
  module DashboardsHelper
    def check_highlight(line)
      if line.include?("[HIGHLIGHT]")
        "<div class='highlight'>#{line.delete('[HIGHLIGHT]')}</div>".html_safe
      else
        line
      end
    end
  end
end
