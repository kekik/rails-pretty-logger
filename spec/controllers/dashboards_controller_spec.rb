require 'rails_helper'

module Rails
  module Pretty
    module Logger

      RSpec.describe DashboardsController, type: :controller do
        routes { Rails::Pretty::Logger::Engine.routes }

        describe "GET #index" do
          it "returns http success" do
            get :index
            expect(response).to have_http_status(:success)
          end
        end

        describe "GET #log_file" do
          it "returns http success" do
            get :log_file, params: {log_file: "development", date_range: {start: Time.now.strftime("%Y-%m-%d") , end: Time.now.strftime("%Y-%m-%d") }}
            expect(response).to have_http_status(:success)
          end
        end

      end

    end
  end
end
