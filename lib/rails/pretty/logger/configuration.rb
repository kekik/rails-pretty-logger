module Rails::Pretty::Logger
  class Configuration
    attr_accessor :authenticate_with, :log_line_parser, :max_file_size, :tail_lines
    attr_writer :read_only

    def initialize
      @authenticate_with = nil
      @log_line_parser = nil
      @read_only = Rails.env.production?
      @max_file_size = nil
      @tail_lines = 500
    end

    def read_only?
      @read_only == true
    end
  end
end
