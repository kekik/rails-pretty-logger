require "rails/pretty/logger/engine"

module Rails
  module Pretty
    module Logger

      class PrettyLogger

        def initialize(params)
          @log_file = File.join(Rails.root, 'log', "#{params[:log_file]}.log")
          @filter_params = params
        end

        def self.logger
          Rails.logger
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

        def error
          @error
        end

        def clear_logs
          open(@log_file, File::TRUNC) {}
        end

        def start_date
          if @filter_params[:date_range].present?
            @filter_params[:date_range][:start]
          else
            Time.now.strftime("%Y-%m-%d")
          end
        end

        def end_date
          if @filter_params[:date_range].present?
            @filter_params[:date_range][:end]
          else
            Time.now.strftime("%Y-%m-%d")
          end
        end

        def file_list
          PrettyLogger.get_log_file_list
        end

        def filter_logs_with_date(file)
          arr = []
          start = false

          IO.foreach(file) do |line|
            if get_date_from_log_line(line)
              start = true
              arr.push(line)
            elsif start && !(line_include_date?(line))
              arr.push(line)
            else
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
          if @filter_params[:log_file].include?("test")
            get_test_logs(file)
          else
            filter_logs_with_date(file)
          end
        end

        def get_date_from_log_line(line)
          params = @filter_params[:date_range]
          if line_include_date?(line)
            date_string_index = line.index("at ")
            string_date = line[date_string_index .. date_string_index + 13]
            date = string_date.to_date.strftime("%Y-%m-%d")
            if params.present?
              date.between?(params[:start], params[:end])
            else
              date.between?(Time.now.strftime("%Y-%m-%d"), Time.now.strftime("%Y-%m-%d"))
            end
          end
        end

        def line_include_date?(line)
          line.include?("Started")
        end

        def validate_date
          params = @filter_params[:date_range]
          if params.present?
            if (params[:start].present? && params[:end].present?)
              if (params[:start] > params[:end])
                "End Date should not be less than Start Date."
              end
            elsif  params[:start].blank? || params[:end].blank?
              "Start and End Date must be given."
            end
          end
        end

        def log_data
          error = validate_date
          divider = set_divider_value
          logs = get_logs_from_file(@log_file)
          logs_count =  (logs.count.to_f / divider).ceil
          paginated_logs = logs[ @filter_params[:page].to_i * divider ..
          (@filter_params[:page].to_i * divider) + divider ]
          data = {}
          data[:logs_count] = logs_count
          data[:paginated_logs] = paginated_logs
          data[:error] = error
          return data
        end

        def set_divider_value
          if @filter_params[:date_range].blank?
            100
          elsif @filter_params[:date_range][:divider].blank?
            100
          else
            @filter_params[:date_range][:divider].to_i
          end
        end
      end
    end
  end
end
