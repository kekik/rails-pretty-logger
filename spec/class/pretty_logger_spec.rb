require 'rails_helper'
require 'helper/rspec_file'

module Rails
  module Pretty
    module Logger

      RSpec.describe PrettyLogger do
        describe "check log file" do

          before do
            logs = DummyLog::LOG
            file_path = File.join(Rails.root, 'log', "rspec_test.log")
            File.open(file_path,"w") {|f| f.write(logs) }
          end

          it "has log file" do
            params = ActionController::Parameters.new(date_range: {"end" => Time.now.strftime("%Y-%m-%d"),
              "start" => Time.now.strftime("%Y-%m-%d")}, log_file: File.join(Rails.root, 'log', "rspec_test.log") )
              subject = PrettyLogger.new(params)
              expect(subject.log_data[:error]).to be_nil
              expect(subject.log_data[:logs_count]).to eq(1)
              expect(subject.log_data[:paginated_logs][0]).to include(Time.now.strftime("%Y-%m-%d"))
            end

            it "does not validate without end date" do
              params = ActionController::Parameters.new(date_range: {"end" => (Time.now - 1.days).strftime("%Y-%m-%d"),
                "start" => Time.now.strftime("%Y-%m-%d")}, log_file: File.join(Rails.root, 'log', "rspec_test.log") )
                subject = PrettyLogger.new( params )
                expect(subject.log_data[:error]).to eq("End Date should not be less than Start Date.")
              end

              it "gets log file list" do
                log_file_count = PrettyLogger.get_log_file_list.count
                PrettyLogger.highlight(File.exist?(File.join(Rails.root, 'log', "rspec_test.log")))
                expect(log_file_count).to be >= 1
              end

              after do
                file_path = File.join(Rails.root, 'log', "rspec_test.log")
                File.delete(file_path)
              end
            end

          end
        end
      end
    end
