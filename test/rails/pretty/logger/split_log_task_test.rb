require "test_helper"
require "rake"

class SplitLogTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("split_log")
    Rake::Task["split_log"].reenable

    @source_log = Rails.root.join("log", "old_production.log")
    File.write(@source_log, <<~LOG)
      Started GET "/first" for 127.0.0.1 at 2026-05-10 11:17:00 +0300
      Processing by TestController#index as HTML
      Completed 200 OK in 12ms
      Started GET "/second" for 127.0.0.1 at 2026-05-10 12:01:00 +0300
      Processing by TestController#index as HTML
      Completed 200 OK in 9ms
    LOG
  end

  teardown do
    FileUtils.rm_f(@source_log)
    FileUtils.rm_rf(Rails.root.join("log", "hourly"))
  end

  test "splits old logs into hourly files" do
    output, = capture_io do
      Rake::Task["split_log"].invoke("archive", @source_log.to_s)
    end

    first_hour = Rails.root.join("log", "hourly", "2026", "05", "10", "archive.log.20260510_1100")
    second_hour = Rails.root.join("log", "hourly", "2026", "05", "10", "archive.log.20260510_1200")

    assert_includes output, "It's done"
    assert_path_exists first_hour
    assert_path_exists second_hour
    assert_includes File.read(first_hour), "/first"
    assert_includes File.read(second_hour), "/second"
  end
end
