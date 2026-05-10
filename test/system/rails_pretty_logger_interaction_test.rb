require "application_system_test_case"

class RailsPrettyLoggerInteractionTest < ApplicationSystemTestCase
  setup do
    @log_file = Rails.root.join("log", "system.log")
    @hourly_dir = Rails.root.join("log", "hourly", "2026", "05", "10")
    @hourly_file = @hourly_dir.join("production.log.20260510_1100")
    @older_hourly_dir = Rails.root.join("log", "hourly", "2025", "04", "09")
    @older_hourly_file = @older_hourly_dir.join("production.log.20250409_0800")

    FileUtils.mkdir_p(@hourly_dir)
    FileUtils.mkdir_p(@older_hourly_dir)
    File.write(@log_file, dashboard_log)
    File.write(@hourly_file, hourly_log("HOURLY 2026 ENTRY", Time.local(2026, 5, 10, 11, 0, 0)))
    File.write(@older_hourly_file, hourly_log("HOURLY 2025 ENTRY", Time.local(2025, 4, 9, 8, 0, 0)))
  end

  teardown do
    FileUtils.rm_f(@log_file)
    FileUtils.rm_rf(Rails.root.join("log", "hourly"))
  end

  test "loads engine stylesheet through the asset pipeline" do
    visit "/rails-pretty-logger"

    assert_selector "link[rel='stylesheet'][href*='rails/pretty/logger/application']", visible: false
    assert_selector "script[src*='rails/pretty/logger/application']", visible: false
    assert_equal "rgb(241, 241, 241)", page.evaluate_script("getComputedStyle(document.body).backgroundColor")
  end

  test "opens a log file and filters it by date range" do
    visit "/rails-pretty-logger"

    accept_confirm do
      click_link "System.log"
    end

    assert_text "TODAY ENTRY"
    assert_no_text "YESTERDAY ENTRY"

    find("input[name='date_range[start]']").set(Date.yesterday.to_s)
    find("input[name='date_range[end]']").set(Date.yesterday.to_s)
    click_button "Submit"

    assert_text "YESTERDAY ENTRY"
    assert_no_text "TODAY ENTRY"
  end

  test "opens tail view for a log file" do
    File.open(@log_file, "w") do |file|
      520.times { |index| file.puts "TAIL SYSTEM ENTRY #{index}" }
    end

    visit "/rails-pretty-logger"

    accept_confirm do
      click_link "System.log"
    end

    click_link "Tail last 500 lines"

    assert_text "TAIL SYSTEM ENTRY 519"
    assert_no_text "TAIL SYSTEM ENTRY 0"
    click_link "Filtered view"
    assert_selector "input[name='date_range[start]']", visible: false
  end

  test "filters log content and severity in the browser" do
    File.write(@log_file, <<~LOG)
      Started GET "/payments" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300
      INFO payment accepted
      ERROR payment failed
      ERROR profile failed
    LOG

    visit "/rails-pretty-logger"

    accept_confirm do
      click_link "System.log"
    end

    fill_in "Search", with: "payment"
    select "ERROR", from: "Severity"
    click_button "Filter"

    assert_text "ERROR payment failed"
    assert_no_text "INFO payment accepted"
    assert_no_text "ERROR profile failed"

    click_link "Tail last 500 lines"

    assert_text "ERROR payment failed"
    assert_no_text "INFO payment accepted"
    assert_no_text "ERROR profile failed"
  end

  test "clear logs form requires confirmation" do
    visit "/rails-pretty-logger"

    accept_confirm do
      click_link "System.log"
    end

    assert_text "TODAY ENTRY"

    dismiss_confirm do
      click_button "Clear logs"
    end

    assert_text "TODAY ENTRY"
    assert_includes File.read(@log_file), "TODAY ENTRY"

    accept_confirm do
      click_button "Clear logs"
    end

    assert_no_text "TODAY ENTRY"
    assert_empty File.read(@log_file)
  end

  test "filters sorts and opens hourly log files" do
    visit "/rails-pretty-logger/hourly_logs"

    assert_equal ["2025/04/09 : 0800", "2026/05/10 : 1100"], hourly_log_links

    click_link "Sort desc"

    assert_equal ["2026/05/10 : 1100", "2025/04/09 : 0800"], hourly_log_links

    fill_in "Search", with: "missing-log"
    click_button "Search"
    assert_no_text "2026/05/10"
    assert_no_text "2025/04/09"

    fill_in "Search", with: "2026"
    click_button "Search"
    assert_text "2026/05/10"
    assert_no_text "2025/04/09"

    accept_confirm do
      click_link "2026/05/10 : 1100"
    end

    assert_text "HOURLY 2026 ENTRY"
    assert_no_text "HOURLY 2025 ENTRY"
  end

  test "shows hourly empty state" do
    FileUtils.rm_rf(Rails.root.join("log", "hourly"))

    visit "/rails-pretty-logger/hourly_logs"

    assert_text "There is no log file to show"
  end

  test "does not execute escaped log content in the browser" do
    File.write(@log_file, <<~LOG)
      Started GET "/xss" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300
      [HIGHLIGHT]<script>window.__railsPrettyLoggerHighlightXss = true</script>
      Parameters: {"payload"=>"<script>window.__railsPrettyLoggerParamsXss = true</script>"}
    LOG

    visit "/rails-pretty-logger"

    accept_confirm do
      click_link "System.log"
    end

    assert_text "<script>window.__railsPrettyLoggerHighlightXss = true</script>"
    assert_text "<script>window.__railsPrettyLoggerParamsXss = true</script>"
    assert_not page.evaluate_script("window.__railsPrettyLoggerHighlightXss === true")
    assert_not page.evaluate_script("window.__railsPrettyLoggerParamsXss === true")
  end

  private

  def dashboard_log
    <<~LOG
      Started GET "/today" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300
      Completed TODAY ENTRY
      Started GET "/yesterday" for 127.0.0.1 at #{Date.yesterday.strftime("%Y-%m-%d")} 11:17:00 +0300
      Completed YESTERDAY ENTRY
    LOG
  end

  def hourly_log(message, time)
    <<~LOG
      Started GET "/hourly" for 127.0.0.1 at #{time.strftime("%Y-%m-%d")} #{time.strftime("%H:%M:%S")} +0300
      Completed #{message}
    LOG
  end

  def hourly_log_links
    page.all(".name").map(&:text)
  end
end
