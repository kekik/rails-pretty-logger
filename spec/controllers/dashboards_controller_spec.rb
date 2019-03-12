require 'rails_helper'

module Rails
  module Pretty
    module Logger

      RSpec.describe DashboardsController, type: :controller do
        routes { Rails::Pretty::Logger::Engine.routes }

        before do
          @log = 'Started GET "/rails-pretty-logger/dashboards" for 127.0.0.1 at ' + Time.now.strftime("%Y-%m-%d").to_s + ' 11:17:00 +0300
          Processing by Rails::Pretty::Logger::DashboardsController#index as HTML
          Rendering /home/project/rails/dum/rails-pretty-logger/app/views/rails/pretty/logger/dashboards/index.html.erb within layouts/rails/pretty/logger/application
          Rendered /home/project/rails/dum/rails-pretty-logger/app/views/rails/pretty/logger/dashboards/index.html.erb within layouts/rails/pretty/logger/application (3.3ms)
          Completed 200 OK in 236ms (Views: 233.7ms | ActiveRecord: 0.0ms)'
          file_path = File.join(Rails.root, 'log', "rspec_test.log")
          File.open(file_path,"w") {|f| f.write(@log) }
        end

        describe "GET #index" do
          it "returns http success" do
            get :index
            expect(response).to be_successful
          end
        end

        describe "GET #log_file" do
          it "returns http success" do
            get :logs, params: {log_file: File.join(Rails.root, 'log', "rspec_test.log"),
               date_range: {start: Time.now.strftime("%Y-%m-%d"),
               end: Time.now.strftime("%Y-%m-%d") }}
            expect(response).to be_successful
          end
        end

        after do
          file_path = File.join(Rails.root, 'log', "rspec_test.log")
          File.delete(file_path)
        end

      end

    end
  end
end
