require "test_helper"
require "rails/pretty/logger/console_logger"

module Rails
  module Pretty
    module Logger
      class RailsLoggerTest < ActiveSupport::TestCase
        setup do
          @log_name = "rotation_test"
          @log_file = Rails.root.join("log", "#{@log_name}.log")
          @hourly_root = Rails.root.join("log", "hourly")
          FileUtils.rm_f(@log_file)
          FileUtils.rm_rf(@hourly_root)
        end

        teardown do
          @logger&.close
          FileUtils.rm_f(@log_file)
          FileUtils.rm_rf(@hourly_root)
        end

        test "rotates current log file into the hourly directory" do
          @logger = ConsoleLogger.new(@log_name, "hourly", file_count: 5)
          @logger.info("rotated message")

          logdev.shift_log_period(Time.local(2026, 5, 10, 11, 0, 0))

          rotated_file = Rails.root.join("log", "hourly", "2026", "05", "10", "#{@log_name}.log.20260510_1100")

          assert_path_exists rotated_file
          assert_path_exists @log_file
          assert_includes File.read(rotated_file), "rotated message"
        end

        test "keeps hourly rotated files within file_count" do
          old_file = Rails.root.join("log", "hourly", "2026", "05", "10", "#{@log_name}.log.20260510_1000")
          FileUtils.mkdir_p(old_file.dirname)
          File.write(old_file, "old hourly log")

          @logger = ConsoleLogger.new(@log_name, "hourly", file_count: 1)
          @logger.info("new hourly log")

          logdev.shift_log_period(Time.local(2026, 5, 10, 11, 0, 0))

          rotated_files = Dir[Rails.root.join("log", "hourly", "2026", "**", "*")].reject { |file| File.directory?(file) }
          new_file = Rails.root.join("log", "hourly", "2026", "05", "10", "#{@log_name}.log.20260510_1100")

          assert_equal 1, rotated_files.count
          assert_path_exists new_file
          assert_not File.exist?(old_file)
        end

        test "keeps hourly cleanup scoped to the current log name" do
          old_file = Rails.root.join("log", "hourly", "2026", "05", "10", "#{@log_name}.log.20260510_1000")
          other_log_file = Rails.root.join("log", "hourly", "2026", "05", "10", "other.log.20260510_0900")
          FileUtils.mkdir_p(old_file.dirname)
          File.write(old_file, "old hourly log")
          File.write(other_log_file, "other hourly log")

          @logger = ConsoleLogger.new(@log_name, "hourly", file_count: 1)
          @logger.info("new hourly log")

          logdev.shift_log_period(Time.local(2026, 5, 10, 11, 0, 0))

          own_rotated_files = Dir[Rails.root.join("log", "hourly", "**", "#{@log_name}.log.*")]
          new_file = Rails.root.join("log", "hourly", "2026", "05", "10", "#{@log_name}.log.20260510_1100")

          assert_equal [new_file.to_s], own_rotated_files.sort
          assert_path_exists other_log_file
        end

        test "removes empty hourly directories after deleting old files" do
          old_file = Rails.root.join("log", "hourly", "2025", "01", "01", "#{@log_name}.log.20250101_0100")
          FileUtils.mkdir_p(old_file.dirname)
          File.write(old_file, "old hourly log")

          @logger = ConsoleLogger.new(@log_name, "hourly", file_count: 1)
          @logger.info("new hourly log")

          logdev.shift_log_period(Time.local(2026, 5, 10, 11, 0, 0))

          assert_not File.exist?(old_file)
          assert_not Dir.exist?(Rails.root.join("log", "hourly", "2025"))
        end

        private

        def logdev
          @logger.instance_variable_get(:@logdev)
        end
      end
    end
  end
end
