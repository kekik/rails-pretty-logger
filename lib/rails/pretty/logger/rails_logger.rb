module Rails
  module Pretty
    module Logger

      class RailsLogger < ::Logger

        def initialize(logdev, shift_age = 0, shift_size = 1048576, level: DEBUG,
          progname: nil, formatter: nil, datetime_format: nil,
          shift_period_suffix: '%Y%m%d')
          self.level = level
          self.progname = progname
          @default_formatter = Formatter.new
          self.datetime_format = datetime_format
          self.formatter = formatter
          @logdev = nil
          if logdev
            @logdev = LoggerDevice.new(logdev, :shift_age => shift_age,
              :shift_size => shift_size,
              :shift_period_suffix => shift_period_suffix)
            end
          end

          module Period
            module_function

            SiD = 24 * 60 * 60

            def next_rotate_time(now, shift_age)
              case shift_age
              when 'hourly'
                t = Time.mktime(now.year, now.month, now.mday, now.hour ,now.min + 1)
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
                t = Time.mktime(now.year, now.month, now.mday, now.hour ,now.min + 1)
              end
              t
            end

            def previous_period_end(now, shift_age)
              case shift_age
              when 'hourly'
                t = Time.mktime(now.year, now.month, now.mday, now.hour ,now.min - 1)
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

            def initialize(*args)
              super(*args)
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
              old_log_path = Rails.root.join(age_file)
              new_path = File.join(Rails.root, 'log', suffix_year, suffix_month, suffix_day)
              FileUtils.mkdir_p new_path
              FileUtils.mv old_log_path, new_path, :force => true
              @dev = create_logfile(@filename)
              return true
            end
          end

        end
      end
    end
  end
