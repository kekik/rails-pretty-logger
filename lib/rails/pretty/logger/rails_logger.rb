
require "fileutils"
require "logger"

module Rails::Pretty::Logger

  class RailsLogger < ::Logger

    def initialize(logdev, shift_age = 0, shift_size = 1048576, file_count: nil, level: DEBUG,
      progname: nil, formatter: nil, datetime_format: nil,
      shift_period_suffix: '%Y%m%d')

      super(nil, level: level, progname: progname, formatter: formatter, datetime_format: datetime_format)
      @logdev = nil
      if logdev
        log_name = Rails.root.join("log", "#{logdev}.log").to_s
        @logdev = LoggerDevice.new(log_name, :shift_age => shift_age,
          :shift_size => shift_size,
          :shift_period_suffix => shift_period_suffix, file_count: file_count )
        end
      end

      module Period
        module_function

        SiD = 24 * 60 * 60

        def next_rotate_time(now, shift_age)
          case shift_age
          when 'hourly'
            t = Time.mktime(now.year, now.month, now.mday, now.hour + 1)
          when 'daily'
            t = Time.mktime(now.year, now.month, now.mday) + SiD
          when 'weekly'
            t = Time.mktime(now.year, now.month, now.mday) + SiD * (7 - now.wday)
          when 'monthly'
            t = Time.mktime(now.year, now.month, 1) + SiD * 32
            return Time.mktime(t.year, t.month, 1)
          else
            return now
          end
          if (t.hour.nonzero? or t.min.nonzero? or t.sec.nonzero?) && shift_age != 'hourly'
            hour = t.hour
            t = Time.mktime(t.year, t.month, t.mday)
            t += SiD if hour > 12

          elsif shift_age == 'hourly'
            t = Time.mktime(now.year, now.month, now.mday, now.hour + 1)
          end
          t
        end

        def previous_period_end(now, shift_age)
          case shift_age
          when 'hourly'
            t = Time.mktime(now.year, now.month, now.mday, now.hour - 1)
          when 'daily'
            t = Time.mktime(now.year, now.month, now.mday) - SiD / 2
          when 'weekly'
            t = Time.mktime(now.year, now.month, now.mday) - (SiD * now.wday + SiD / 2)
          when 'monthly'
            t = Time.mktime(now.year, now.month, 1) - SiD / 2
          else
            return now
          end

          if shift_age == 'hourly'

            Time.mktime(t.year, t.month, t.mday, t.hour, t.min, t.sec)
          else
            Time.mktime(t.year, t.month, t.mday, 23, 59, 59)
          end

        end
      end

      class LoggerDevice < LogDevice
        include Period

        def initialize(log = nil, shift_age: nil, shift_size: nil, shift_period_suffix: nil, file_count: nil)
          @dev = @filename = @shift_age = @shift_size = @shift_period_suffix = @file_count = nil
          mon_initialize
          set_dev(log)
          if @filename
            @shift_age = shift_age || 7
            @shift_size = shift_size || 1048576
            @shift_period_suffix = shift_period_suffix || '%Y%m%d'
            @file_count = file_count || 48
            unless @shift_age.is_a?(Integer)
              base_time = @dev.respond_to?(:stat) ? @dev.stat.mtime : Time.now
              @next_rotate_time = next_rotate_time(base_time, @shift_age)
            end
          end
        end

        def shift_log_period(period_end)
          suffix = period_end.strftime(@shift_period_suffix)

          suffix_year = period_end.strftime('%Y')
          suffix_month = period_end.strftime('%m')
          suffix_day = period_end.strftime('%d')

          if @shift_age == 'hourly'
            suffix = period_end.strftime('%Y%m%d_%H%M')
          end

          age_file = "#{@filename}.#{suffix}"

          if FileTest.exist?(age_file)
            # try to avoid filename crash caused by Timestamp change.
            idx = 0
            # .99 can be overridden; avoid too much file search with 'loop do'
            while idx < 100
              idx += 1
              age_file = "#{@filename}.#{suffix}.#{idx}"
              break unless FileTest.exist?(age_file)
            end
          end

          @dev.close rescue nil

          File.rename("#{@filename}", age_file)
          new_path = File.join(Rails.root, 'log', 'hourly', suffix_year, suffix_month, suffix_day)
          FileUtils.mkdir_p new_path
          FileUtils.mv age_file, new_path, :force => true
          delete_old_hourly_files
          @dev = create_logfile(@filename)
          return true
        end

        def delete_old_hourly_files
          log_files = hourly_log_files
          while log_files.length > @file_count
            delete_old_file(log_files.min_by { |log_file| hourly_log_sort_key(log_file) })
            log_files = hourly_log_files
          end
        end

        def hourly_log_files
          log_prefix = "#{File.basename(@filename)}."
          Dir[File.join(Rails.root, 'log', 'hourly', '**', '*')]
            .select { |file| File.file?(file) && File.basename(file).start_with?(log_prefix) }
        end

        def hourly_log_sort_key(file)
          File.basename(file)[/\.([0-9]{8}_[0-9]{4})(?:\.[0-9]+)?\z/, 1] || File.mtime(file).utc.strftime("%Y%m%d_%H%M")
        end

        def delete_old_file(file_path)
          day_dir = File.dirname(file_path)
          month_dir = File.expand_path("..",day_dir)
          year_dir = File.expand_path("../..",day_dir)
          File.delete(file_path) if File.exist?(file_path)
          Dir.rmdir(day_dir) if Dir.exist?(day_dir) && Dir.empty?(day_dir)
          Dir.rmdir(month_dir) if Dir.exist?(month_dir) && Dir.empty?(month_dir)
          Dir.rmdir(year_dir) if Dir.exist?(year_dir) && Dir.empty?(year_dir)
        end
      end

    end
  end
