# frozen_string_literal: true

module Rails
  module PrettyLogger
    class ConsoleFormatter < ::Logger::Formatter
      def call(severity, timestamp, _progname, msg)
        formatted_severity = format('%-5s', severity.to_s)
        formatted_time = timestamp.strftime('%Y-%m-%d %H:%M:%S')
        "#{formatted_time} || #{formatted_severity}| #{msg}\n"
      end
    end
  end
end
