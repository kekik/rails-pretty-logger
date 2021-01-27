# frozen_string_literal: true

module Rails
  module PrettyLogger
    class RailsLogger < ::Logger
      def initialize(
        logdev,
        shift_age = 0,
        shift_size = 1_048_576,
        file_count: nil,
        level: DEBUG,
        progname: nil,
        formatter: nil,
        datetime_format: nil,
        shift_period_suffix: '%Y%m%d'
      )
        self.level = level
        self.progname = progname
        @default_formatter = Formatter.new
        self.datetime_format = datetime_format
        self.formatter = formatter
        @logdev = nil
        return unless logdev

        log_name = "log/#{logdev}.log"
        @logdev = LoggerDevice.new(
          log_name,
          shift_age: shift_age,
          shift_size: shift_size,
          shift_period_suffix: shift_period_suffix,
          file_count: file_count,
        )
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
            t = Time.mktime(now.year, now.month,
                            now.mday) + SiD * (7 - now.wday)
          when 'monthly'
            t = Time.mktime(now.year, now.month, 1) + SiD * 32
            return Time.mktime(t.year, t.month, 1)
          else
            return now
          end

          if [t.hour, t.min, t.sec].any?(&:positive?) && shift_age != 'hourly'
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
            t = Time.mktime(now.year, now.month,
                            now.mday) - (SiD * now.wday + SiD / 2)
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
          return unless @filename

          @shift_age = shift_age || 7
          @shift_size = shift_size || 1_048_576
          @shift_period_suffix = shift_period_suffix || '%Y%m%d'
          @file_count = file_count || 48
          return if @shift_age.is_a?(Integer)

          base_time = @dev.respond_to?(:stat) ? @dev.stat.mtime : Time.now
          @next_rotate_time = next_rotate_time(base_time, @shift_age)
        end

        def shift_log_period(period_end)
          suffix = period_end.strftime(@shift_period_suffix)

          suffix_year = period_end.strftime('%Y')
          suffix_month = period_end.strftime('%m')
          suffix_day = period_end.strftime('%d')

          suffix = period_end.strftime('%Y%m%d_%H%M') if @shift_age == 'hourly'

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

          # delete old files
          log_files = Dir[Rails.root.join('log', 'hourly', suffix_year, '**',
                                          '*')].reject do |fn|
            File.directory?(fn)
          end
          while log_files.length > @file_count
            arr = log_files.reduce([]) do |memo, log_file|
              memo << File.ctime(log_file).to_i
            end
            file_index = arr.index(arr.min)
            file_path = log_files[file_index]
            delete_old_file(file_path)
            log_files = Dir[Rails.root.join('log', 'hourly', suffix_year,
                                            '**', '*')].reject do |fn|
              File.directory?(fn)
            end
          end

          begin
            @dev.close
          rescue StandardError
            nil
          end

          File.rename(@filename.to_s, age_file)
          old_log_path = Rails.root.join(age_file)
          new_path = Rails.root.join('log', 'hourly', suffix_year,
                                     suffix_month, suffix_day)
          FileUtils.mkdir_p new_path
          FileUtils.mv old_log_path, new_path, force: true
          @dev = create_logfile(@filename)
          true
        end

        def delete_old_file(file_path)
          day_dir = File.dirname(file_path)
          month_dir = File.expand_path('..', day_dir)
          year_dir = File.expand_path('../..', day_dir)
          File.delete(file_path) if File.exist?(file_path)
          Dir.rmdir(day_dir) if Dir.empty?(day_dir)
          Dir.rmdir(month_dir) if month_dir.empty?
          Dir.rmdir(year_dir) if year_dir.empty?
        end
      end
    end
  end
end
