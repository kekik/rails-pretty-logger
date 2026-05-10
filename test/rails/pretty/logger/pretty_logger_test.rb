require "test_helper"
require "stringio"

module Rails
  module Pretty
    module Logger
      class PrettyLoggerTest < ActiveSupport::TestCase
        setup do
          @log_file = Rails.root.join("log", "pretty_logger_test.log")
          File.write(@log_file, DummyLog.entry)
        end

        teardown do
          FileUtils.rm_f(@log_file)
        end

        test "returns paginated log data for a valid date range" do
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: @log_file.to_s,
              date_range: {
                start: Date.current.to_s,
                end: Date.current.to_s,
                divider: "10"
              }
            )
          )

          data = logger.log_data

          assert_nil data[:error]
          assert_equal 1, data[:logs_count]
          assert_includes data[:paginated_logs].first, Date.current.to_s
        end

        test "validates date ranges" do
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: @log_file.to_s,
              date_range: {
                start: Date.current.to_s,
                end: Date.yesterday.to_s
              }
            )
          )

          assert_equal "End Date should not be less than Start Date.", logger.log_data[:error]
        end

        test "lists log files with sizes" do
          logs = PrettyLogger.get_log_file_list.values

          assert logs.any? { |log| log[:file_name] == @log_file.to_s }
          assert logs.all? { |log| log.key?(:file_size) }
        end

        test "does not include hourly files in the main log file list" do
          hourly_file = Rails.root.join("log", "hourly", "2026", "05", "10", "pretty_logger_test.log.20260510_1100")
          FileUtils.mkdir_p(hourly_file.dirname)
          File.write(hourly_file, DummyLog.entry)

          logs = PrettyLogger.get_log_file_list.values

          assert logs.any? { |log| log[:file_name] == @log_file.to_s }
          assert_not logs.any? { |log| log[:file_name] == hourly_file.to_s }
        ensure
          FileUtils.rm_rf(Rails.root.join("log", "hourly"))
        end

        test "clears a selected log file" do
          PrettyLogger.new(ActionController::Parameters.new(log_file: @log_file.to_s)).clear_logs

          assert_empty File.read(@log_file)
        end

        test "rejects log files outside the Rails log directory" do
          outside_log = Rails.root.join("tmp", "pretty_logger_outside.log")
          FileUtils.mkdir_p(outside_log.dirname)
          File.write(outside_log, DummyLog.entry)

          assert_raises PrettyLogger::InvalidLogFile do
            PrettyLogger.new(ActionController::Parameters.new(log_file: outside_log.to_s))
          end
        ensure
          FileUtils.rm_f(outside_log) if outside_log
        end

        test "rejects symlinks that point outside the Rails log directory" do
          outside_log = Rails.root.join("tmp", "pretty_logger_symlink_target.log")
          log_link = Rails.root.join("log", "pretty_logger_symlink.log")
          FileUtils.mkdir_p(outside_log.dirname)
          File.write(outside_log, DummyLog.entry)
          FileUtils.ln_s(outside_log, log_link)

          assert_raises PrettyLogger::InvalidLogFile do
            PrettyLogger.new(ActionController::Parameters.new(log_file: log_link.to_s))
          end
        ensure
          FileUtils.rm_f(log_link) if log_link
          FileUtils.rm_f(outside_log) if outside_log
        end

        test "resolves relative log file names inside the Rails log directory" do
          logger = PrettyLogger.new(ActionController::Parameters.new(log_file: @log_file.basename.to_s))

          assert_equal @log_file.realpath.to_s, logger.log_file
        end

        test "uses default divider when divider is not positive" do
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: @log_file.to_s,
              date_range: {
                start: Date.current.to_s,
                end: Date.current.to_s,
                divider: "0"
              }
            )
          )

          assert_equal 1, logger.log_data[:logs_count]
        end

        test "highlight writes a tagged log entry" do
          original_logger = Rails.logger
          output = StringIO.new
          Rails.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(output))

          PrettyLogger.highlight("readme marker")

          assert_includes output.string, "HIGHLIGHT"
          assert_includes output.string, "readme marker"
        ensure
          Rails.logger = original_logger
        end
      end
    end
  end
end
