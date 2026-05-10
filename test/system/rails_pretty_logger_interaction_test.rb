require "application_system_test_case"

class RailsPrettyLoggerInteractionTest < ApplicationSystemTestCase
  setup do
    @log_file = Rails.root.join("log", "system_test.log")
    @hourly_dir = Rails.root.join("log", "hourly", "2026", "05", "10")
    @hourly_file = @hourly_dir.join("production.log.20260510_1100")

    FileUtils.mkdir_p(@hourly_dir)
    File.write(@log_file, DummyLog.entry)
    File.write(@hourly_file, DummyLog.entry)
  end

  teardown do
    FileUtils.rm_f(@log_file)
    FileUtils.rm_rf(Rails.root.join("log", "hourly"))
  end

  test "loads engine stylesheet through the asset pipeline" do
    visit "/rails-pretty-logger"

    assert_selector "link[rel='stylesheet'][href*='rails/pretty/logger/application']", visible: false
    assert_equal "rgb(241, 241, 241)", page.evaluate_script("getComputedStyle(document.body).backgroundColor")
  end

  test "opens a log file from the dashboard" do
    visit "/rails-pretty-logger"

    click_link "System_test.log"

    assert_text "Completed 200 OK"
    assert_selector "input[name='date_range[start]']", visible: false
  end

  test "filters hourly log files with server-rendered GET params" do
    visit "/rails-pretty-logger/hourly_logs"

    assert_text "2026/05/10"

    fill_in "Search", with: "missing-log"
    click_button "Search"
    assert_no_text "2026/05/10"

    fill_in "Search", with: "2026"
    click_button "Search"
    assert_text "2026/05/10"
  end
end
