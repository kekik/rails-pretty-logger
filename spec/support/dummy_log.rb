# frozen_string_literal: true

module Support
  DUMMY_LOG = <<~RUBY
    Started GET "/rails-pretty_logger/dashboards" for 127.0.0.1 at #{Date.today} 11:17:00 +0300
    Processing by Rails::PrettyLogger::DashboardsController#index as HTML
    Rendering /home/project/rails/dum/rails-pretty_logger/app/views/rails/pretty/logger/dashboards/index.html.erb within layouts/rails/pretty/logger/application
    Rendered /home/project/rails/dum/rails-pretty_logger/app/views/rails/pretty/logger/dashboards/index.html.erb within layouts/rails/pretty/logger/application (3.3ms)
    Completed 200 OK in 236ms (Views: 233.7ms | ActiveRecord: 0.0ms)'
  RUBY
end
