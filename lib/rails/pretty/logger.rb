require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/conversions"
require "fileutils"
require "json"
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
    SEVERITIES = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN].freeze
    LINE_INDEX_CACHE_LIMIT = 32
    TAIL_READ_CHUNK_SIZE = 64 * 1024
    STRUCTURED_TIMESTAMP_KEYS = %w[@timestamp timestamp time datetime created_at].freeze
    STRUCTURED_SEVERITY_KEYS = %w[severity level log_level].freeze

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

    def self.structured_log_payload(line)
      payload = JSON.parse(line)
      payload if payload.is_a?(Hash)
    rescue JSON::ParserError, TypeError
      nil
    end

    def self.custom_log_metadata(line)
      parser = Rails::Pretty::Logger.configuration.log_line_parser
      return {} unless parser.respond_to?(:call)

      metadata = parser.call(line)
      metadata.is_a?(Hash) ? metadata : {}
    end

    def self.fetch_line_index_cache(cache_key, signature)
      entry_key = [cache_key, signature]

      line_index_cache_mutex.synchronize do
        if line_index_cache.key?(entry_key)
          line_index_cache_order.delete(entry_key)
          line_index_cache_order << entry_key
          return line_index_cache.fetch(entry_key)
        end
      end

      offsets = yield.freeze

      line_index_cache_mutex.synchronize do
        line_index_cache[entry_key] = offsets
        line_index_cache_order.delete(entry_key)
        line_index_cache_order << entry_key

        while line_index_cache_order.length > LINE_INDEX_CACHE_LIMIT
          line_index_cache.delete(line_index_cache_order.shift)
        end
      end

      offsets
    end

    def self.clear_line_index_cache!
      line_index_cache_mutex.synchronize do
        line_index_cache.clear
        line_index_cache_order.clear
      end
    end

    def self.clear_line_index_cache_for!(log_file)
      line_index_cache_mutex.synchronize do
        line_index_cache.delete_if { |(cache_key, _signature), _offsets| cache_key.first == log_file }
        line_index_cache_order.delete_if { |cache_key, _signature| cache_key.first == log_file }
      end
    end

    def self.line_index_cache
      @line_index_cache ||= {}
    end

    def self.line_index_cache_order
      @line_index_cache_order ||= []
    end

    def self.line_index_cache_mutex
      @line_index_cache_mutex ||= Mutex.new
    end

    def clear_logs
      File.open(@log_file, File::TRUNC) {}
      self.class.clear_line_index_cache_for!(@log_file)
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

      each_filtered_log_line_with_offset(file) { |line, _offset| yield line }
    end

    def each_filtered_log_line_with_offset(file)
      return enum_for(:each_filtered_log_line_with_offset, file) unless block_given?

      start = false

      each_raw_log_line_with_offset(file) do |line, offset|
        if get_date_from_log_line(line)
          start = true
          yield line, offset
        elsif start && !(line_include_date?(line))
          yield line, offset
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

      each_log_line_with_offset(file) { |line, _offset| yield line }
    end

    def each_log_line_with_offset(file)
      return enum_for(:each_log_line_with_offset, file) unless block_given?

      if test_log?(file) || hourly_log?(file)
        each_raw_log_line_with_offset(file) { |line, offset| yield line, offset }
      else
        each_filtered_log_line_with_offset(file) { |line, offset| yield line, offset }
      end
    end

    def each_raw_log_line_with_offset(file)
      return enum_for(:each_raw_log_line_with_offset, file) unless block_given?

      File.open(file, "r") do |io|
        until io.eof?
          offset = io.pos
          line = io.gets
          yield line, offset if line
        end
      end
    end

    def get_date_from_log_line(line)
      date = date_from_log_line(line)
      if date.present?
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
      date_from_log_line(line).present?
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
      return grouped_log_data(error, divider) if request_grouping?

      page_start = @filter_params[:page].to_i * divider
      page_end = page_start + divider

      self.class.ensure_file_size_within_limit!(@log_file)

      line_offsets = cached_log_line_offsets
      paginated_logs = read_log_lines_at_offsets(@log_file, line_offsets[page_start...page_end] || [])

      data = {}
      data[:logs_count] = (line_offsets.length.to_f / divider).ceil
      data[:paginated_logs] = paginated_logs
      data[:error] = error
      return data
    end

    def tail_log_data
      self.class.ensure_file_size_within_limit!(@log_file)

      lines = tail_lines(@log_file, self.class.tail_lines).select { |line| line_matches_filters?(line) }
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

    def line_matches_filters?(line)
      query = @filter_params[:query].to_s.strip
      return false if query.present? && !line.downcase.include?(query.downcase)

      severity = @filter_params[:severity].to_s.upcase
      return true unless SEVERITIES.include?(severity)

      structured_severity = structured_log_severity(line)
      return structured_severity == severity if structured_severity.present?

      line.match?(/\b#{Regexp.escape(severity)}\b/i)
    end

    def tail_lines(file, count)
      count = count.to_i
      return [] unless count.positive?

      File.open(file, "rb") do |io|
        offset = io.size
        return [] if offset.zero?

        chunks = []
        newline_count = 0

        while offset.positive? && newline_count <= count
          chunk_size = [TAIL_READ_CHUNK_SIZE, offset].min
          offset -= chunk_size
          io.seek(offset)

          chunk = io.read(chunk_size)
          chunks.unshift(chunk)
          newline_count += chunk.count("\n")
        end

        chunks.join.lines.last(count).map { |line| line.force_encoding(Encoding.default_external) }
      end
    end

    def request_grouping?
      @filter_params[:group].to_s == "request"
    end

    def cached_log_line_offsets
      self.class.fetch_line_index_cache(log_line_index_cache_key, log_file_signature) do
        build_log_line_offsets
      end
    end

    def build_log_line_offsets
      offsets = []

      each_log_line_with_offset(@log_file) do |line, offset|
        offsets << offset if line_matches_filters?(line)
      end

      offsets
    end

    def read_log_lines_at_offsets(file, offsets)
      File.open(file, "r") do |io|
        offsets.map do |offset|
          io.seek(offset)
          io.gets
        end.compact
      end
    end

    def log_line_index_cache_key
      [
        @log_file,
        date_filtered_log? ? start_date : nil,
        date_filtered_log? ? end_date : nil,
        @filter_params[:query].to_s.strip.downcase,
        normalized_severity_filter,
        Rails::Pretty::Logger.configuration.log_line_parser&.object_id
      ]
    end

    def log_file_signature
      stat = File.stat(@log_file)
      [stat.size, stat.mtime.to_f, stat.ctime.to_f]
    end

    def date_filtered_log?
      !test_log?(@log_file) && !hourly_log?(@log_file)
    end

    def normalized_severity_filter
      severity = @filter_params[:severity].to_s.upcase
      SEVERITIES.include?(severity) ? severity : nil
    end

    def grouped_log_data(error, divider)
      self.class.ensure_file_size_within_limit!(@log_file)

      group_count = 0
      paginated_groups = []
      page_start = @filter_params[:page].to_i * divider
      page_end = page_start + divider

      each_request_group(@log_file) do |group|
        next unless group_matches_filters?(group)

        paginated_groups << group if group_count >= page_start && group_count < page_end
        group_count += 1
      end

      {
        logs_count: (group_count.to_f / divider).ceil,
        paginated_logs: paginated_groups,
        error: error
      }
    end

    def each_request_group(file)
      return enum_for(:each_request_group, file) unless block_given?

      current_group = nil

      each_log_line(file) do |line|
        if (metadata = request_start_metadata(line))
          yield current_group if current_group
          current_group = metadata.merge(lines: [line])
        elsif current_group
          current_group[:lines] << line
          current_group.merge!(request_completion_metadata(line) || {})
        else
          current_group = { type: :ungrouped, lines: [line] }
        end
      end

      yield current_group if current_group
    end

    def group_matches_filters?(group)
      group.fetch(:lines).any? { |line| line_matches_filters?(line) }
    end

    def request_start_metadata(line)
      metadata = custom_log_metadata(line)
      request_method = metadata_value(metadata, :request_method, :method)
      request_path = metadata_value(metadata, :request_path, :path)

      if request_method.present? && request_path.present?
        return {
          type: :request,
          method: request_method.to_s,
          path: request_path.to_s,
          ip: metadata_value(metadata, :request_ip, :ip),
          started_at: metadata_value(metadata, :request_started_at, :started_at, :timestamp, :time).to_s
        }
      end

      match = line.strip.match(/\AStarted\s+(?<method>[A-Z]+)\s+"(?<path>[^"]+)"(?:\s+for\s+(?<ip>\S+))?\s+at\s+(?<timestamp>.+)\z/)
      return unless match

      {
        type: :request,
        method: match[:method],
        path: match[:path],
        ip: match[:ip],
        started_at: match[:timestamp].strip
      }
    end

    def request_completion_metadata(line)
      metadata = custom_log_metadata(line)
      response_status = metadata_value(metadata, :response_status, :status)
      duration = metadata_value(metadata, :duration, :request_duration)

      if response_status.present? || duration.present?
        return {
          status: response_status.to_s,
          duration: duration.to_s
        }
      end

      match = line.strip.match(/\ACompleted\s+(?<status>\d{3}).*?\sin\s+(?<duration>[\d.]+ms)/)
      return unless match

      {
        status: match[:status],
        duration: match[:duration]
      }
    end

    def date_from_log_line(line)
      timestamp = custom_log_timestamp(line) || request_timestamp(line) || structured_log_timestamp(line)
      timestamp&.to_date&.strftime("%Y-%m-%d")
    rescue Date::Error, NoMethodError
      nil
    end

    def request_timestamp(line)
      match = line.strip.match(/\AStarted\s+.*\sat\s+(?<timestamp>.+)\z/)
      match[:timestamp] if match
    end

    def structured_log_timestamp(line)
      payload = self.class.structured_log_payload(line)
      return unless payload

      STRUCTURED_TIMESTAMP_KEYS.each do |key|
        return payload[key].to_s if payload[key].present?
      end

      nil
    end

    def structured_log_severity(line)
      severity = custom_log_severity(line)
      return severity if severity.present?

      payload = self.class.structured_log_payload(line)
      return unless payload

      STRUCTURED_SEVERITY_KEYS.each do |key|
        severity = payload[key].to_s.upcase
        return severity if SEVERITIES.include?(severity)
      end

      nested_log = payload["log"]
      return unless nested_log.respond_to?(:[])

      nested_severity = nested_log["level"].to_s.upcase
      nested_severity if SEVERITIES.include?(nested_severity)
    end

    def custom_log_timestamp(line)
      metadata_value(custom_log_metadata(line), :timestamp, :time, :datetime, :created_at)
    end

    def custom_log_severity(line)
      severity = metadata_value(custom_log_metadata(line), :severity, :level, :log_level).to_s.upcase
      severity if SEVERITIES.include?(severity)
    end

    def custom_log_metadata(line)
      self.class.custom_log_metadata(line)
    end

    def metadata_value(metadata, *keys)
      keys.each do |key|
        string_key = key.to_s
        return metadata[string_key] if metadata.key?(string_key)
        return metadata[key] if metadata.key?(key)
      end

      nil
    end

  end
end
