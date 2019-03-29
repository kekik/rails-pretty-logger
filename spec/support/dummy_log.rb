module DummyLog
  LOG =
    'Started GET "/rails-pretty-logger/dashboards" for 127.0.0.1 at ' + Time.now.strftime("%Y-%m-%d").to_s + ' 11:17:00 +0300
    Processing by Rails::Pretty::Logger::DashboardsController#index as HTML
    Rendering /home/project/rails/dum/rails-pretty-logger/app/views/rails/pretty/logger/dashboards/index.html.erb within layouts/rails/pretty/logger/application
    Rendered /home/project/rails/dum/rails-pretty-logger/app/views/rails/pretty/logger/dashboards/index.html.erb within layouts/rails/pretty/logger/application (3.3ms)
    Completed 200 OK in 236ms (Views: 233.7ms | ActiveRecord: 0.0ms)'
  
end
