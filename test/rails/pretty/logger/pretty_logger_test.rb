require "test_helper"
require "minitest/mock"
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

        test "filters log data by content query and severity" do
          File.write(@log_file, <<~LOG)
            INFO normal request
            WARN payment warning
            ERROR payment failed
          LOG
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: @log_file.to_s,
              query: "payment",
              severity: "ERROR"
            )
          )

          data = logger.log_data

          assert_equal 1, data[:logs_count]
          assert_equal ["ERROR payment failed\n"], data[:paginated_logs]
        end

        test "filters structured json log data by date content and severity" do
          structured_log = Rails.root.join("log", "structured_production.log")
          File.write(structured_log, <<~LOG)
            {"timestamp":"#{Date.yesterday.iso8601}T10:00:00Z","level":"ERROR","message":"payment from yesterday failed"}
            {"timestamp":"#{Date.current.iso8601}T10:00:00Z","level":"INFO","message":"payment accepted"}
            {"timestamp":"#{Date.current.iso8601}T10:01:00Z","level":"ERROR","message":"payment failed","request_id":"abc-123"}
          LOG
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: structured_log.to_s,
              query: "payment",
              severity: "ERROR",
              date_range: {
                start: Date.current.to_s,
                end: Date.current.to_s
              }
            )
          )

          data = logger.log_data

          assert_equal 1, data[:logs_count]
          assert_equal 1, data[:paginated_logs].count
          assert_includes data[:paginated_logs].first, "payment failed"
          assert_includes data[:paginated_logs].first, "abc-123"
        ensure
          FileUtils.rm_f(structured_log) if structured_log
        end

        test "uses configured log line parser for date and severity filters" do
          custom_log = Rails.root.join("log", "custom_parser_production.log")
          File.write(custom_log, <<~LOG)
            CUSTOM #{Date.yesterday.iso8601} ERROR payment failed yesterday
            CUSTOM #{Date.current.iso8601} INFO payment accepted
            CUSTOM #{Date.current.iso8601} ERROR payment failed today
          LOG
          Rails::Pretty::Logger.configure do |config|
            config.log_line_parser = ->(line) do
              if (match = line.match(/\ACUSTOM (?<date>\d{4}-\d{2}-\d{2}) (?<severity>\w+)/))
                { timestamp: "#{match[:date]}T10:00:00Z", severity: match[:severity] }
              end
            end
          end
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: custom_log.to_s,
              query: "payment",
              severity: "ERROR",
              date_range: {
                start: Date.current.to_s,
                end: Date.current.to_s
              }
            )
          )

          data = logger.log_data

          assert_equal 1, data[:logs_count]
          assert_equal ["CUSTOM #{Date.current.iso8601} ERROR payment failed today\n"], data[:paginated_logs]
        ensure
          FileUtils.rm_f(custom_log) if custom_log
        end

        test "ignores unknown severity filters" do
          File.write(@log_file, "ERROR unknown severity should still render\n")
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: @log_file.to_s,
              severity: "NOPE"
            )
          )

          assert_equal ["ERROR unknown severity should still render\n"], logger.log_data[:paginated_logs]
        end

        test "groups rails request logs when request grouping is enabled" do
          File.write(@log_file, <<~LOG)
            Started GET "/first" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300
            Processing by HomeController#index as HTML
            Completed 200 OK in 12ms
            Started POST "/second" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:18:00 +0300
            ERROR payment failed
            Completed 500 Internal Server Error in 25ms
          LOG
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: @log_file.to_s,
              group: "request",
              date_range: {
                start: Date.current.to_s,
                end: Date.current.to_s,
                divider: "1"
              }
            )
          )

          data = logger.log_data
          group = data[:paginated_logs].first

          assert_equal 2, data[:logs_count]
          assert_equal :request, group[:type]
          assert_equal "GET", group[:method]
          assert_equal "/first", group[:path]
          assert_equal "200", group[:status]
          assert_equal "12ms", group[:duration]
          assert_includes group[:lines].join, "Processing by HomeController"
        end

        test "uses configured log line parser for request grouping" do
          custom_log = Rails.root.join("log", "custom_request_parser_production.log")
          File.write(custom_log, <<~LOG)
            REQ #{Date.current.iso8601} PATCH /custom
            custom request body
            RESP 202 7ms
          LOG
          Rails::Pretty::Logger.configure do |config|
            config.log_line_parser = ->(line) do
              if (match = line.match(/\AREQ (?<date>\d{4}-\d{2}-\d{2}) (?<method>\w+) (?<path>\S+)/))
                {
                  timestamp: "#{match[:date]}T11:00:00Z",
                  request_method: match[:method],
                  request_path: match[:path]
                }
              elsif (match = line.match(/\ARESP (?<status>\d{3}) (?<duration>\S+)/))
                {
                  response_status: match[:status],
                  duration: match[:duration]
                }
              end
            end
          end
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: custom_log.to_s,
              group: "request",
              date_range: {
                start: Date.current.to_s,
                end: Date.current.to_s
              }
            )
          )

          group = logger.log_data[:paginated_logs].first

          assert_equal :request, group[:type]
          assert_equal "PATCH", group[:method]
          assert_equal "/custom", group[:path]
          assert_equal "202", group[:status]
          assert_equal "7ms", group[:duration]
          assert_includes group[:lines].join, "custom request body"
        ensure
          FileUtils.rm_f(custom_log) if custom_log
        end

        test "filters request groups by matching lines inside the group" do
          File.write(@log_file, <<~LOG)
            Started GET "/first" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300
            INFO payment accepted
            Completed 200 OK in 12ms
            Started POST "/second" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:18:00 +0300
            ERROR payment failed
            Completed 500 Internal Server Error in 25ms
          LOG
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: @log_file.to_s,
              group: "request",
              query: "payment",
              severity: "ERROR",
              date_range: {
                start: Date.current.to_s,
                end: Date.current.to_s,
                divider: "10"
              }
            )
          )

          data = logger.log_data

          assert_equal 1, data[:logs_count]
          assert_equal "/second", data[:paginated_logs].first[:path]
          assert_includes data[:paginated_logs].first[:lines].join, "ERROR payment failed"
        end

        test "reuses cached request group index for repeated grouping" do
          File.write(@log_file, <<~LOG)
            Started GET "/first" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300
            Completed 200 OK in 12ms
            Started POST "/second" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:18:00 +0300
            Completed 500 Internal Server Error in 25ms
          LOG
          params = {
            log_file: @log_file.to_s,
            group: "request",
            date_range: {
              start: Date.current.to_s,
              end: Date.current.to_s,
              divider: "1"
            }
          }

          PrettyLogger.new(ActionController::Parameters.new(params)).log_data
          logger = PrettyLogger.new(ActionController::Parameters.new(params.merge(page: "1")))
          logger.define_singleton_method(:build_request_group_index) do
            flunk "grouped log_data should reuse cached request group index"
          end

          data = logger.log_data

          assert_equal 2, data[:logs_count]
          assert_equal "/second", data[:paginated_logs].first[:path]
        end

        test "loads request group index from persistent cache" do
          File.write(@log_file, <<~LOG)
            Started GET "/persisted" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300
            Completed 200 OK in 12ms
          LOG
          params = {
            log_file: @log_file.to_s,
            group: "request",
            date_range: {
              start: Date.current.to_s,
              end: Date.current.to_s
            }
          }

          PrettyLogger.new(ActionController::Parameters.new(params)).log_data
          PrettyLogger.clear_line_index_memory_cache!
          logger = PrettyLogger.new(ActionController::Parameters.new(params))
          logger.define_singleton_method(:build_request_group_index) do
            flunk "grouped log_data should load persisted request group index"
          end

          data = logger.log_data

          assert_equal 1, data[:logs_count]
          assert_equal "/persisted", data[:paginated_logs].first[:path]
        end

        test "paginates large log files without materializing the full log array" do
          large_log = Rails.root.join("log", "large_production.log")
          File.open(large_log, "w") do |file|
            1_000.times do |index|
              file.puts %(Started GET "/large/#{index}" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300)
              file.puts "Completed LARGE ENTRY #{index}"
            end
          end

          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: large_log.to_s,
              page: "3",
              date_range: {
                start: Date.current.to_s,
                end: Date.current.to_s,
                divider: "25"
              }
            )
          )

          logger.define_singleton_method(:get_logs_from_file) do |_file|
            flunk "log_data should stream lines instead of loading the full log file"
          end

          data = logger.log_data

          assert_equal 80, data[:logs_count]
          assert_equal 25, data[:paginated_logs].count
          assert_includes data[:paginated_logs].join, "LARGE ENTRY"
        ensure
          FileUtils.rm_f(large_log) if large_log
        end

        test "reuses cached line offsets for repeated large log pagination" do
          large_log = Rails.root.join("log", "cached_large_production.log")
          File.open(large_log, "w") do |file|
            60.times do |index|
              file.puts %(Started GET "/cached/#{index}" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300)
            end
          end
          params = {
            log_file: large_log.to_s,
            page: "0",
            date_range: {
              start: Date.current.to_s,
              end: Date.current.to_s,
              divider: "10"
            }
          }

          PrettyLogger.new(ActionController::Parameters.new(params)).log_data
          logger = PrettyLogger.new(ActionController::Parameters.new(params.merge(page: "1")))
          logger.define_singleton_method(:build_log_line_offsets) do
            flunk "log_data should reuse cached offsets instead of scanning the file again"
          end

          data = logger.log_data

          assert_equal 6, data[:logs_count]
          assert_equal 10, data[:paginated_logs].count
          assert_includes data[:paginated_logs].first, "/cached/10"
        ensure
          FileUtils.rm_f(large_log) if large_log
        end

        test "loads cached line offsets from persistent cache" do
          large_log = Rails.root.join("log", "persisted_cached_large_production.log")
          File.open(large_log, "w") do |file|
            20.times do |index|
              file.puts %(Started GET "/persisted-cached/#{index}" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300)
            end
          end
          params = {
            log_file: large_log.to_s,
            page: "0",
            date_range: {
              start: Date.current.to_s,
              end: Date.current.to_s,
              divider: "10"
            }
          }

          PrettyLogger.new(ActionController::Parameters.new(params)).log_data
          PrettyLogger.clear_line_index_memory_cache!
          logger = PrettyLogger.new(ActionController::Parameters.new(params.merge(page: "1")))
          logger.define_singleton_method(:build_log_line_offsets) do
            flunk "log_data should load persisted offsets instead of scanning the file again"
          end

          data = logger.log_data

          assert_equal 2, data[:logs_count]
          assert_equal 10, data[:paginated_logs].count
          assert_includes data[:paginated_logs].first, "/persisted-cached/10"
        ensure
          FileUtils.rm_f(large_log) if large_log
        end

        test "invalidates cached line offsets when log file changes" do
          large_log = Rails.root.join("log", "changing_large_production.log")
          File.write(large_log, %(Started GET "/before" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:17:00 +0300\n))
          params = ActionController::Parameters.new(
            log_file: large_log.to_s,
            date_range: {
              start: Date.current.to_s,
              end: Date.current.to_s,
              divider: "10"
            }
          )

          PrettyLogger.new(params).log_data
          File.open(large_log, "a") do |file|
            file.puts %(Started GET "/after" for 127.0.0.1 at #{Date.current.strftime("%Y-%m-%d")} 11:18:00 +0300)
          end

          data = PrettyLogger.new(params).log_data

          assert_equal 1, data[:logs_count]
          assert_includes data[:paginated_logs].join, "/after"
        ensure
          FileUtils.rm_f(large_log) if large_log
        end

        test "returns only the configured tail lines" do
          tail_log = Rails.root.join("log", "tail_production.log")
          File.open(tail_log, "w") do |file|
            10.times { |index| file.puts "TAIL ENTRY #{index}" }
          end
          Rails::Pretty::Logger.configure { |config| config.tail_lines = 3 }
          logger = PrettyLogger.new(ActionController::Parameters.new(log_file: tail_log.to_s))

          data = logger.tail_log_data

          assert_equal 1, data[:logs_count]
          assert_equal ["TAIL ENTRY 7\n", "TAIL ENTRY 8\n", "TAIL ENTRY 9\n"], data[:paginated_logs]
        ensure
          FileUtils.rm_f(tail_log) if tail_log
        end

        test "tail log data reads from the end of the file" do
          tail_log = Rails.root.join("log", "tail_reverse_read_production.log")
          File.open(tail_log, "w") do |file|
            2_000.times { |index| file.puts "TAIL REVERSE ENTRY #{index}" }
          end
          Rails::Pretty::Logger.configure { |config| config.tail_lines = 2 }
          logger = PrettyLogger.new(ActionController::Parameters.new(log_file: tail_log.to_s))

          data = nil
          IO.stub(:foreach, ->(*) { flunk "tail_log_data should not scan the file from the first line" }) do
            data = logger.tail_log_data
          end

          assert_equal ["TAIL REVERSE ENTRY 1998\n", "TAIL REVERSE ENTRY 1999\n"], data[:paginated_logs]
        ensure
          FileUtils.rm_f(tail_log) if tail_log
        end

        test "tail log data preserves the final line without a trailing newline" do
          tail_log = Rails.root.join("log", "tail_without_newline_production.log")
          File.write(tail_log, "TAIL ENTRY 1\nTAIL ENTRY 2\nTAIL ENTRY 3")
          Rails::Pretty::Logger.configure { |config| config.tail_lines = 2 }
          logger = PrettyLogger.new(ActionController::Parameters.new(log_file: tail_log.to_s))

          data = logger.tail_log_data

          assert_equal ["TAIL ENTRY 2\n", "TAIL ENTRY 3"], data[:paginated_logs]
        ensure
          FileUtils.rm_f(tail_log) if tail_log
        end

        test "filters tail log data by content query and severity" do
          tail_log = Rails.root.join("log", "tail_filter_production.log")
          File.write(tail_log, <<~LOG)
            INFO payment succeeded
            ERROR payment failed
            ERROR other failure
          LOG
          logger = PrettyLogger.new(
            ActionController::Parameters.new(
              log_file: tail_log.to_s,
              query: "payment",
              severity: "ERROR"
            )
          )

          data = logger.tail_log_data

          assert_equal 1, data[:logs_count]
          assert_equal ["ERROR payment failed\n"], data[:paginated_logs]
        ensure
          FileUtils.rm_f(tail_log) if tail_log
        end

        test "uses a safe default when tail lines is invalid" do
          Rails::Pretty::Logger.configure { |config| config.tail_lines = 0 }

          assert_equal 500, PrettyLogger.tail_lines
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
