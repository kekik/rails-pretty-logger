require 'rails_helper'
require 'support/dummy_log'

module Rails
  module Pretty
    module Logger

      RSpec.describe DashboardsController, type: :controller do
        routes { Rails::Pretty::Logger::Engine.routes }

        before do
          logs = DummyLog::LOG
          file_path = File.join(Rails.root, 'log', "rspec_test.log")
          File.open(file_path,"w") {|f| f.write(logs) }
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
