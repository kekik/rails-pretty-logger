require "rails/pretty/logger/engine"

module Rails
  module Pretty
    module Logger

      class PrettyLogger

        def initialize( params, divider = 100 )

          @log_file = File.join(Rails.root, 'log', "#{params[:log_file]}.log")
          @log_file_list = PrettyLogger.get_log_file_list
          @filter_params = params
          @error = validate_date()
          @logs = get_logs_from_file(@log_file)
          @logs_count =  (@logs.count.to_f / divider).ceil
          @paginated_logs = @logs[ params[:page].to_i * divider .. (params[:page].to_i * divider) + divider ]

        end

        def self.logger
          Rails.logger
        end

        def error
          @error
        end

        def start_date
          @filter_params[:date_range][:start]
        end

        def end_date
          @filter_params[:date_range][:end]
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

        def self.file_size(log_file)
          File.size?("./#{log_file}").to_f / 2**20
        end

        def self.get_log_file_list
          log = {}
          log_files =  Dir["**/*.log"]
          log_files.each_with_index do |log_file,index|
            log[index] = {}
            log[index][:file_name] =  File.basename(log_file, ".log")
            log[index][:file_size] = self.file_size(log_file).round(4)
          end
          return log
        end

        def filter_logs_with_date(file)

          arr = []

          start = false

          IO.foreach(file) do |line|

            line_log_date = get_date_from_log_line(line)

            if line_log_date
              start = true
              arr.push(line)
            elsif start && !(check_line_include_date(line))
              arr.push(line)
            elsif line_log_date == false
              start = false
            end
          end
          return arr
        end

        def get_test_logs(file)

          arr = []

          IO.foreach(file) do |line|
            arr.push(line)
          end
          return arr
        end

        def get_logs_from_file(file)
          unless @filter_params[:log_file].include?("test")
            filter_logs_with_date(file)
          else
            get_test_logs(file)
          end
        end

        def get_date_from_log_line(line)
          if check_line_include_date(line)
            date_string_index = line.index("at ")
            string_date = line[date_string_index .. date_string_index + 13]
            date = string_date.to_date.strftime("%Y-%m-%d")
            date.between?( @filter_params[:date_range][:start], @filter_params[:date_range][:end]  )
          end
        end

        def check_line_include_date(line)
          line.include?("Started")
        end

        def validate_date()
          params = @filter_params[:date_range]

          if (params[:start].present? && params[:end].present?)
            if (params[:start] > params[:end])
              "End Date should not be less than Start Date."
            end
          elsif  params[:start].blank? || params[:end].blank?
            "Start and End Date must be given."
          end
        end

      end
    end
  end
end
