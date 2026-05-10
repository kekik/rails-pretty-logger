require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/conversions"
require "fileutils"
require "pathname"
require "rails/pretty/logger/configuration"
require "rails/pretty/logger/engine"

module Rails::Pretty::Logger
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end

  class PrettyLogger
    class InvalidLogFile < StandardError; end
    class FileTooLarge < StandardError; end

    attr_reader :log_file

    def initialize(params)
      @filter_params = params
      @log_file = self.class.resolve_log_file(params[:log_file])
    end

    def self.logger
      Rails.logger
    end

    def self.highlight(log)
      self.logger.tagged('HIGHLIGHT') { logger.info log }
    end

    def self.file_size(log_file)
      File.size?("#{log_file}").to_f / 2**20
    end

    def self.log_root
      Rails.root.join("log")
    end

    def self.resolve_log_file(log_file)
      raise InvalidLogFile if log_file.blank?

      candidate = Pathname.new(log_file.to_s)
      candidate = log_root.join(candidate) unless candidate.absolute?

      root_path = real_log_root
      real_path = candidate.realpath

      unless real_path.to_s == root_path.to_s || real_path.to_s.start_with?("#{root_path}/")
        raise InvalidLogFile
      end

      raise InvalidLogFile unless real_path.file?

      real_path.to_s
    rescue Errno::ENOENT, Errno::EACCES, ArgumentError
      raise InvalidLogFile
    end

    def self.real_log_root
      FileUtils.mkdir_p(log_root)
      log_root.realpath
    end

    def self.get_log_file_list
      log_files = Dir[File.join(log_root, "*")].select { |file| File.file?(file) }
      logs_atr(log_files)
    end

    def self.get_hourly_log_file_list
      log_files = Dir[File.join(log_root, "hourly", "**", "*")].select { |file| File.file?(file) }.sort
      logs_atr(log_files)
    end

    def self.logs_atr(log_files)
      log = {}
      log_files.each_with_index do |log_file,index|
        log[index] = {}
        log[index][:file_name] =  log_file
        log[index][:file_size] = self.file_size(log_file).round(4)
      end
      log
    end

    def self.ensure_file_size_within_limit!(log_file)
      max_file_size = Rails::Pretty::Logger.configuration.max_file_size
      return if max_file_size.blank?

      raise FileTooLarge if File.size(log_file) > max_file_size.to_i
    end

    def self.tail_lines
      Rails::Pretty::Logger.configuration.tail_lines.to_i.positive? ? Rails::Pretty::Logger.configuration.tail_lines.to_i : 500
    end

    def clear_logs
      File.open(@log_file, File::TRUNC) {}
    end

    def start_date
      @filter_params.dig(:date_range, :start) || Time.now.strftime("%Y-%m-%d")
    end

    def end_date
      @filter_params.dig(:date_range, :end) || Time.now.strftime("%Y-%m-%d")
    end

    def filter_logs_with_date(file)
      each_filtered_log_line(file).to_a
    end

    def each_filtered_log_line(file)
      return enum_for(:each_filtered_log_line, file) unless block_given?

      start = false

      IO.foreach(file) do |line|
        if get_date_from_log_line(line)
          start = true
          yield line
        elsif start && !(line_include_date?(line))
          yield line
        else
          start = false
        end
      end
    end

    def get_test_logs(file)
      IO.foreach(file).to_a
    end

    def get_logs_from_file(file)
      each_log_line(file).to_a
    end

    def each_log_line(file)
      return enum_for(:each_log_line, file) unless block_given?

      if test_log?(file) || hourly_log?(file)
        IO.foreach(file) { |line| yield line }
      else
        each_filtered_log_line(file) { |line| yield line }
      end
    end

    def get_date_from_log_line(line)
      params = @filter_params[:date_range]
      if line_include_date?(line)
        date_string_index = line.index("at ")
        string_date = line[date_string_index .. date_string_index + 13]
        date = string_date.to_date.strftime("%Y-%m-%d")
        start_date = @filter_params.dig(:date_range, :start)
        end_date = @filter_params.dig(:date_range, :end)
        if start_date.present? && end_date.present?
          date.between?(start_date, end_date)
        else
          date.between?(Time.now.strftime("%Y-%m-%d"), Time.now.strftime("%Y-%m-%d"))
        end
      end
    end

    def line_include_date?(line)
      line.include?("Started")
    end

    def validate_date
      start_date = @filter_params.dig(:date_range, :start)
      end_date = @filter_params.dig(:date_range, :end)
      if (start_date.present? && end_date.present?)
        if (start_date > end_date)
          "End Date should not be less than Start Date."
        end
      else
        "Start and End Date must be given."
      end
    end

    def log_data
      error = validate_date
      divider = set_divider_value
      line_count = 0
      paginated_logs = []
      page_start = @filter_params[:page].to_i * divider
      page_end = page_start + divider

      self.class.ensure_file_size_within_limit!(@log_file)

      each_log_line(@log_file) do |line|
        paginated_logs << line if line_count >= page_start && line_count < page_end
        line_count += 1
      end

      data = {}
      data[:logs_count] = (line_count.to_f / divider).ceil
      data[:paginated_logs] = paginated_logs
      data[:error] = error
      return data
    end

    def tail_log_data
      self.class.ensure_file_size_within_limit!(@log_file)

      lines = tail_lines(@log_file, self.class.tail_lines)
      {
        logs_count: lines.any? ? 1 : 0,
        paginated_logs: lines,
        error: nil
      }
    end

    def set_divider_value
      if @filter_params[:date_range].blank?
        100
      elsif @filter_params[:date_range][:divider].blank?
        100
      else
        divider = @filter_params[:date_range][:divider].to_i
        divider.positive? ? divider : 100
      end
    end

    def test_log?(file)
      File.basename(file).include?("test")
    end

    def hourly_log?(file)
      file.include?("#{File::SEPARATOR}hourly#{File::SEPARATOR}")
    end

    def tail_lines(file, count)
      buffer = []
      IO.foreach(file) do |line|
        buffer << line
        buffer.shift if buffer.length > count
      end
      buffer
    end

  end
end
