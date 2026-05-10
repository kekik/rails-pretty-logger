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
          FileUtils.rm_rf(Rails.root.join("tmp", "rails_pretty_logger"))
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

        test "does not overwrite an existing hourly file for the same timestamp" do
          existing_file = Rails.root.join("log", "hourly", "2026", "05", "10", "#{@log_name}.log.20260510_1100")
          FileUtils.mkdir_p(existing_file.dirname)
          File.write(existing_file, "existing hourly log")

          @logger = ConsoleLogger.new(@log_name, "hourly", file_count: 5)
          @logger.info("new rotated message")

          logdev.shift_log_period(Time.local(2026, 5, 10, 11, 0, 0))

          collision_file = Rails.root.join("log", "hourly", "2026", "05", "10", "#{@log_name}.log.20260510_1100.1")

          assert_includes File.read(existing_file), "existing hourly log"
          assert_path_exists collision_file
          assert_includes File.read(collision_file), "new rotated message"
        end

        test "keeps both repeated DST hour rotations" do
          @logger = ConsoleLogger.new(@log_name, "hourly", file_count: 5)
          @logger.info("first dst hour")
          logdev.shift_log_period(Time.new(2026, 11, 1, 1, 0, 0, "-04:00"))

          @logger.info("second dst hour")
          logdev.shift_log_period(Time.new(2026, 11, 1, 1, 0, 0, "-05:00"))

          first_file = Rails.root.join("log", "hourly", "2026", "11", "01", "#{@log_name}.log.20261101_0100")
          second_file = Rails.root.join("log", "hourly", "2026", "11", "01", "#{@log_name}.log.20261101_0100.1")

          assert_includes File.read(first_file), "first dst hour"
          assert_includes File.read(second_file), "second dst hour"
        end

        test "calculates next hourly rotation across spring DST jump" do
          skip "timezone data is not available" unless timezone_data_path

          with_timezone("America/New_York") do
            next_rotation = RailsLogger::Period.next_rotate_time(Time.local(2026, 3, 8, 1, 30, 0), "hourly")

            assert_equal "2026-03-08 03:00:00 -0400", next_rotation.strftime("%Y-%m-%d %H:%M:%S %z")
          end
        end

        test "waits for an existing rotation lock before moving files" do
          @logger = ConsoleLogger.new(@log_name, "hourly", file_count: 5)
          @logger.info("locked rotation message")
          lock_path = Rails.root.join("tmp", "rails_pretty_logger", "#{@log_name}.log.rotate.lock")
          rotated_file = Rails.root.join("log", "hourly", "2026", "05", "10", "#{@log_name}.log.20260510_1100")
          FileUtils.mkdir_p(lock_path.dirname)
          lock_file = File.open(lock_path, File::RDWR | File::CREAT, 0644)
          lock_file.flock(File::LOCK_EX)
          error = nil

          thread = Thread.new do
            logdev.shift_log_period(Time.local(2026, 5, 10, 11, 0, 0))
          rescue => exception
            error = exception
          end

          sleep 0.2

          assert thread.alive?
          assert_not File.exist?(rotated_file)

          lock_file.flock(File::LOCK_UN)
          thread.join(2)

          assert_nil error
          assert_not thread.alive?
          assert_path_exists rotated_file
          assert_includes File.read(rotated_file), "locked rotation message"
        ensure
          thread&.kill if thread&.alive?
          lock_file&.flock(File::LOCK_UN) rescue nil
          lock_file&.close
        end

        test "concurrent rotations use unique destination files" do
          @logger = ConsoleLogger.new(@log_name, "hourly", file_count: 5)
          second_logger = ConsoleLogger.new(@log_name, "hourly", file_count: 5)
          @logger.info("first concurrent message")
          second_logger.info("second concurrent message")
          errors = Queue.new
          ready = Queue.new
          start = Queue.new
          devices = [logdev, second_logger.instance_variable_get(:@logdev)]

          threads = devices.map do |device|
            Thread.new do
              ready << true
              start.pop
              device.shift_log_period(Time.local(2026, 5, 10, 11, 0, 0))
            rescue => exception
              errors << exception
            end
          end

          devices.length.times { ready.pop }
          devices.length.times { start << true }
          threads.each { |thread| thread.join(2) }
          exceptions = []
          exceptions << errors.pop until errors.empty?

          rotated_files = Dir[Rails.root.join("log", "hourly", "2026", "05", "10", "#{@log_name}.log.20260510_1100*")]

          assert threads.none?(&:alive?)
          assert_empty exceptions
          assert_equal 2, rotated_files.count
          assert_equal rotated_files.uniq.sort, rotated_files.sort
        ensure
          second_logger&.close
          threads&.each { |thread| thread.kill if thread.alive? }
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

        def with_timezone(zone)
          old_tz = ENV["TZ"]
          old_tzdir = ENV["TZDIR"]
          ENV["TZDIR"] = timezone_data_path
          ENV["TZ"] = zone
          yield
        ensure
          old_tz.nil? ? ENV.delete("TZ") : ENV["TZ"] = old_tz
          old_tzdir.nil? ? ENV.delete("TZDIR") : ENV["TZDIR"] = old_tzdir
        end

        def timezone_data_path
          @timezone_data_path ||= begin
            Dir["/nix/store/*tzdata*/share/zoneinfo"].find { |path| File.exist?(File.join(path, "America", "New_York")) } ||
              ("/usr/share/zoneinfo" if File.exist?("/usr/share/zoneinfo/America/New_York"))
          end
        end
      end
    end
  end
end
