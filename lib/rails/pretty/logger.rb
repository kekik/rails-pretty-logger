require "rails/pretty/logger/engine"

module Rails
  module Pretty
    module Logger

      class PrettyLogger

        def initialize(log_file = "development.log")
          @log_file = File.join(Rails.root, 'log', log_file)
        end

        def self.logger
          Rails.logger
        end

        def self.highlight(log)
          self.logger.tagged('HIGHLIGHT') { logger.info log }
        end

        def log_file
          @log_file
        end

        def file_size(log_file)
          File.size?("./#{log_file}").to_f / 2**20
        end

        def get_log_list
          log = {}
          log_files =  Dir["**/*.log"]
          log_files.each_with_index do |log_file,index|
            log[index] = {}
            log[index][:file_name] =  File.basename(log_file, ".log")
            log[index][:file_size] = file_size(log_file).round(4)
          end
          return log
        end

        def get_log_line_count(file)
          File.foreach(file).count
        end

        def open_log_page(file, start_date, end_date)

          arr = []

          start = false

          IO.foreach(file).with_index do |line, index|
            if get_log_date(line, start_date, end_date)
              start = true
              arr.push(line)
            elsif start && check_line_include_date(line)
              arr.push(line)
            elsif (get_log_date(line, start_date, end_date)) == false
              start = false
            end
          end
          return arr
        end

        def get_log_date(line, start_date, end_date)
          if line.include?("Started")
            date_string_index = line.index("at ")
            string_date = line[date_string_index .. date_string_index + 13]
            date = string_date.to_date.strftime("%Y-%m-%d")
            date.between?( start_date, end_date  )
          end
        end

        def check_line_include_date(line)
          !(line.include?("Started"))
        end

      end
    end
  end
end
