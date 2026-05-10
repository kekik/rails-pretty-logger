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

  test "rejects log files outside the Rails log directory" do
    outside_log = Rails.root.join("tmp", "outside.log")
    FileUtils.mkdir_p(outside_log.dirname)
    File.write(outside_log, "outside log")

    get "/rails-pretty-logger/dashboards/logs", params: {
      log_file: outside_log.to_s,
      date_range: {
        start: Date.current.to_s,
        end: Date.current.to_s
      }
    }

    assert_response :bad_request
  ensure
    FileUtils.rm_f(outside_log) if outside_log
  end

  test "does not clear files outside the Rails log directory" do
    outside_log = Rails.root.join("tmp", "outside-clear.log")
    FileUtils.mkdir_p(outside_log.dirname)
    File.write(outside_log, "outside log")

    post "/rails-pretty-logger/dashboards/clear_logs", params: {
      log_file: outside_log.to_s
    }

    assert_response :bad_request
    assert_equal "outside log", File.read(outside_log)
  ensure
    FileUtils.rm_f(outside_log) if outside_log
  end

  test "escapes highlighted log content" do
    File.write(@log_file, "#{DummyLog.entry}[HIGHLIGHT]<script>alert(1)</script>\n")

    get "/rails-pretty-logger/dashboards/logs", params: {
      log_file: @log_file.to_s,
      date_range: {
        start: Date.current.to_s,
        end: Date.current.to_s
      }
    }

    assert_response :success
    assert_includes response.body, "&lt;script&gt;alert(1)&lt;/script&gt;"
    assert_not_includes response.body, "<script>alert(1)</script>"
  end

  test "escapes parameter log content" do
    File.write(@log_file, <<~LOG)
      Started GET "/rails-pretty-logger/dashboards" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300
      Parameters: {"query"=>"<script>alert(1)</script>"}
      Completed 200 OK in 12ms
    LOG

    get "/rails-pretty-logger/dashboards/logs", params: {
      log_file: @log_file.to_s,
      date_range: {
        start: Date.current.to_s,
        end: Date.current.to_s
      }
    }

    assert_response :success
    assert_includes response.body, "&lt;script&gt;alert(1)&lt;/script&gt;"
    assert_not_includes response.body, "<script>alert(1)</script>"
  end
end
