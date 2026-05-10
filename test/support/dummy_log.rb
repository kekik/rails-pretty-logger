module DummyLog
  def self.entry(date: Date.current)
    <<~LOG
      Started GET "/rails-pretty-logger/dashboards" for 127.0.0.1 at #{date.strftime("%Y-%m-%d")} 11:17:00 +0300
      Processing by Rails::Pretty::Logger::DashboardsController#index as HTML
      Parameters: {"controller"=>"rails/pretty/logger/dashboards", "action"=>"index"}
      Completed 200 OK in 12ms (Views: 8.0ms | ActiveRecord: 0.0ms)
    LOG
  end
end
