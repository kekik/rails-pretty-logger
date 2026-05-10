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

  test "authentication hook can block engine access" do
    Rails::Pretty::Logger.configure do |config|
      config.authenticate_with = -> { head :unauthorized }
    end

    get "/rails-pretty-logger/dashboards"

    assert_response :unauthorized
  end

  test "legacy authentication hook can block engine access" do
    Rails.application.config.x.rails_pretty_logger.authenticate_with = -> { head :unauthorized }

    get "/rails-pretty-logger/dashboards"

    assert_response :unauthorized
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

  test "filters selected log file by content query and severity" do
    File.write(@log_file, <<~LOG)
      INFO payment accepted
      ERROR payment failed
      ERROR profile failed
    LOG

    get "/rails-pretty-logger/dashboards/logs", params: {
      log_file: @log_file.to_s,
      query: "payment",
      severity: "ERROR"
    }

    assert_response :success
    assert_includes response.body, "ERROR payment failed"
    assert_not_includes response.body, "INFO payment accepted"
    assert_not_includes response.body, "ERROR profile failed"
  end

  test "preserves log filters in pagination links" do
    File.write(@log_file, "ERROR payment failed\nERROR payment failed again\n")

    get "/rails-pretty-logger/dashboards/logs", params: {
      log_file: @log_file.to_s,
      query: "payment",
      severity: "ERROR",
      date_range: {
        divider: "1"
      }
    }

    assert_response :success
    assert_includes response.body, "query=payment"
    assert_includes response.body, "severity=ERROR"
  end

  test "renders selected log file in tail mode" do
    Rails::Pretty::Logger.configure { |config| config.tail_lines = 1 }

    get "/rails-pretty-logger/dashboards/logs", params: {
      log_file: @log_file.to_s,
      mode: "tail"
    }

    assert_response :success
    assert_includes response.body, "Completed 200 OK"
    assert_not_includes response.body, "Started GET"
    assert_includes response.body, "Filtered view"
  end

  test "clears selected log file" do
    post "/rails-pretty-logger/dashboards/clear_logs", params: {
      log_file: @log_file.to_s
    }

    assert_redirected_to "/rails-pretty-logger/dashboards/logs?log_file=#{CGI.escape(@log_file.to_s)}"
    assert_empty File.read(@log_file)
  end

  test "read only mode blocks clearing selected log file" do
    Rails::Pretty::Logger.configure { |config| config.read_only = true }

    post "/rails-pretty-logger/dashboards/clear_logs", params: {
      log_file: @log_file.to_s
    }

    assert_response :forbidden
    assert_includes File.read(@log_file), "Completed 200 OK"
  end

  test "read only mode hides clear buttons" do
    Rails::Pretty::Logger.configure { |config| config.read_only = true }

    get "/rails-pretty-logger/dashboards"

    assert_response :success
    assert_not_includes response.body, "clear_logs"
  end

  test "rejects selected log file when max file size is exceeded" do
    Rails::Pretty::Logger.configure { |config| config.max_file_size = 1 }

    get "/rails-pretty-logger/dashboards/logs", params: {
      log_file: @log_file.to_s,
      date_range: {
        start: Date.current.to_s,
        end: Date.current.to_s
      }
    }

    assert_response 413
    assert_includes response.body, "Log file is too large"
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
