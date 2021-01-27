# frozen_string_literal: true

require_relative './engine'

module Rails
  module PrettyLogger
    class PrettyLogger
      def initialize(params)
        @log_file = params[:log_file]
        @filter_params = params
      end

      def self.logger
        Rails.logger
      end

      def self.highlight(log)
        logger.tagged('HIGHLIGHT') { logger.info log }
      end

      def self.file_size(log_file)
        File.size?(log_file.to_s).to_f / 2**20
      end

      def self.get_log_file_list
        log_files = Dir[Rails.root.join('log', '**.*')]
        logs_atr(log_files)
      end

      def self.get_hourly_log_file_list
        log_files = Dir[Rails.root.join('log', 'hourly', '**', '*.*')]
        logs_atr(log_files)
      end

      def self.logs_atr(log_files)
        log = {}
        log_files.each_with_index do |log_file, index|
          log[index] = {}
          log[index][:file_name] = log_file
          log[index][:file_size] = file_size(log_file).round(4)
        end
        log
      end

      def clear_logs
        File.open(@log_file, 'w')
      end

      def start_date
        @filter_params.dig(:date_range,
                           :start) || Time.now.strftime('%Y-%m-%d')
      end

      def end_date
        @filter_params.dig(:date_range,
                           :end) || Time.now.strftime('%Y-%m-%d')
      end

      def filter_logs_with_date(file)
        arr = []
        start = false

        IO.foreach(file) do |line|
          if get_date_from_log_line(line)
            start = true
            arr.push(line)
          elsif start && !line_include_date?(line)
            arr.push(line)
          else
            start = false
          end
        end
        arr
      end

      def get_test_logs(file)
        arr = []
        IO.foreach(file) do |line|
          arr.push(line)
        end
        arr
      end

      def get_logs_from_file(file)
        if @filter_params[:log_file].include?('test') || @filter_params[:log_file].include?('hourly')
          get_test_logs(file)
        else
          filter_logs_with_date(file)
        end
      end

      def get_date_from_log_line(line)
        params = @filter_params[:date_range]
        return unless line_include_date?(line)

        date_string_index = line.index('at ')
        string_date = line[date_string_index..date_string_index + 13]
        date = string_date.to_date.strftime('%Y-%m-%d')
        start_date = @filter_params.dig(:date_range, :start)
        end_date = @filter_params.dig(:date_range, :end)
        if start_date.present? && end_date.present?
          date.between?(start_date, end_date)
        else
          date.between?(Time.now.strftime('%Y-%m-%d'),
                        Time.now.strftime('%Y-%m-%d'))
        end
      end

      def line_include_date?(line)
        line.include?('Started')
      end

      def validate_date
        start_date = @filter_params.dig(:date_range, :start)
        end_date = @filter_params.dig(:date_range, :end)
        if start_date.present? && end_date.present?
          if start_date > end_date
            'End Date should not be less than Start Date.'
          end
        else
          'Start and End Date must be given.'
        end
      end

      def log_data
        error = validate_date
        divider = set_divider_value
        logs = get_logs_from_file(@log_file)
        logs_count = (logs.count.to_f / divider).ceil
        initial_log_index = @filter_params[:page].to_i * divider
        paginated_logs = logs[initial_log_index..initial_log_index + divider]
        data = {}
        data[:logs_count] = logs_count
        data[:paginated_logs] = paginated_logs
        data[:error] = error
        data
      end

      def set_divider_value
        if @filter_params[:date_range].blank? || @filter_params[:date_range][:divider].blank?
          100
        else
          @filter_params[:date_range][:divider].to_i
        end
      end
    end
  end
end
