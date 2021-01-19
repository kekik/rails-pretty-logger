# frozen_string_literal: true

module Rails
  module PrettyLogger
    module ApplicationHelper
      def modify_name(name)
        "#{name[-13..-10]}/#{name[-9..-8]}/#{name[-7..-6]} : #{name[-4..-1]}"
      end

      def trim_name(name)
        name.split('/log/').last.capitalize
      end
    end
  end
end
