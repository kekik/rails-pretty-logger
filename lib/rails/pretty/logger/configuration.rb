module Rails::Pretty::Logger
  class Configuration
    attr_accessor :authenticate_with, :max_file_size
    attr_writer :read_only

    def initialize
      @authenticate_with = nil
      @read_only = false
      @max_file_size = nil
    end

    def read_only?
      @read_only == true
    end
  end
end
