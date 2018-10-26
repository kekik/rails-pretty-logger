require "rails/pretty/logger/engine"

module Rails
  module Pretty
    module Logger

      class PrettyLogger

        def initialize(log_file = "#{Rails.env}.log", params)
          @log_file = File.join(Rails.root, 'log', log_file)
          @log_file_list = PrettyLogger.get_log_list
          if params[:date_range].present?
            @logs_start_date = params[:date_range][:start]
            @logs_end_date = params[:date_range][:end]
            @logs = PrettyLogger.open_log_page(@log_file, params[:date_range][:start], params[:date_range][:end])
            @logs_count =  (@logs.count.to_f/100).ceil
            @paginated_logs = @logs[ params[:page].to_i * 100 .. (params[:page].to_i * 100) + 100 ]
          end
        end

        def self.logger
          Rails.logger
        end

        def start_date
          @logs_start_date
        end
        def end_date
          @logs_end_date
        end
        def parsed_logs
          @logs
        end

        def file_list
          @log_file_list
        end

        def paginated_logs
          @paginated_logs
        end

        def logs_count
          @logs_count
        end

        def self.highlight(log)
          self.logger.tagged('HIGHLIGHT') { logger.info log }
        end

        def log_file
          @log_file
        end

        def self.file_size(log_file)
          File.size?("./#{log_file}").to_f / 2**20
        end

        def self.get_log_list
          log = {}
          log_files =  Dir["**/*.log"]
          log_files.each_with_index do |log_file,index|
            log[index] = {}
            log[index][:file_name] =  File.basename(log_file, ".log")
            log[index][:file_size] = self.file_size(log_file).round(4)
          end
          return log
        end

        def self.open_log_page(file, start_date, end_date)

          arr = []

          start = false

          IO.foreach(file) do |line|
            if self.get_log_date(line, start_date, end_date)
              start = true
              arr.push(line)
            elsif start && !(self.check_line_include_date(line))
              arr.push(line)
            elsif (self.get_log_date(line, start_date, end_date)) == false
              start = false
            end
          end
          return arr
        end

        def self.get_log_date(line, start_date, end_date)
          if self.check_line_include_date(line)
            date_string_index = line.index("at ")
            string_date = line[date_string_index .. date_string_index + 13]
            date = string_date.to_date.strftime("%Y-%m-%d")
            date.between?( start_date, end_date  )
          end
        end

        def self.check_line_include_date(line)
          line.include?("Started")
        end

      end
    end
  end
end
