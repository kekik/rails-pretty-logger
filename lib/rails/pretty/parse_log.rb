module Rails::Pretty::Logger
  class ParseLog
    attr_accessor :splitted_logs

    def initialize(logs)
      @splitted_logs = []
      splitted_logs = split(logs)
      splitted_logs.each do |log|
        @splitted_logs.push SplittedLog.new(log)
      end
    end

    class SplittedLog
      attr_accessor :log_text
      attr_accessor :log_info

      def initialize(log)
        @id = log[0]
        @log_text = log[1]
        @log_info = log_infos(@log_text)
      end

      def log_infos(arr)
        info = {}
        arr.each do |line|
          if line.include?("Completed")
            index = line.index('Completed')
            info[:code] = line[index + 10 .. index + 12]
          else
            if line.include?("Started GET")
              info[:request] = "GET"
            elsif line.include?("Started POST")
              info[:request] = "POST"
            elsif line.include?("Started PATCH")
              info[:request] = "PATCH"
            elsif line.include?("Started DELETE")
              info[:request] = "DELETE"
            elsif line.include?("Started PUT")
              info[:request] = "PUT"
            end
          end
        end
        info
      end
    end

    def split(logs)
      start = false
      new = Hash.new
      line_index = 0
      logs.each_with_index do |line, index|
        if line_include_start?(line)
          line_index = index
          start = true
          new[line_index] = Array.new
          new[line_index] << line
        elsif line_include_complete?(line)
          new[line_index] = Array.new if new[line_index].nil?
          new[line_index] << line
          start = false
        elsif start
          new[line_index] << line
        end
      end
      new
    end

    def line_include_start?(line)
      line.include?("Started")
    end

    def line_include_complete?(line)
      line.include?("Completed")
    end
  end
end
