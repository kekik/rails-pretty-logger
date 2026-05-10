require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  setup do
    @log_file = Rails.root.join("log", "dashboard_test.log")
    File.write(@log_file, DummyLog.entry)
  end

  teardown do
    FileUtils.rm_f(@log_file)
  end

  test "lists application log files" do
    get "/rails-pretty-logger/dashboards"

    assert_response :success
    assert_includes response.body, "Dashboard_test.log"
  end

  test "renders selected log file" do
    get "/rails-pretty-logger/dashboards/logs", params: {
      log_file: @log_file.to_s,
      date_range: {
        start: Date.current.to_s,
        end: Date.current.to_s
      }
    }

    assert_response :success
    assert_includes response.body, "Completed 200 OK"
  end

  test "clears selected log file" do
    post "/rails-pretty-logger/dashboards/clear_logs", params: {
      log_file: @log_file.to_s
    }

    assert_redirected_to "/rails-pretty-logger/dashboards/logs?log_file=#{CGI.escape(@log_file.to_s)}"
    assert_empty File.read(@log_file)
  end
end
