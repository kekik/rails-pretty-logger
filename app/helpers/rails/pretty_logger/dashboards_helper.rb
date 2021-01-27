# frozen_string_literal: true

module Rails
  module PrettyLogger
    module DashboardsHelper
      def check_highlight(line)
        if line.include?('[HIGHLIGHT]')
          return "<div class='highlight'>#{line.remove('[HIGHLIGHT]')}</div>".html_safe
        end

        if line.include?('Parameters:')
          parse_parameters(line)
        else
          line
        end
      end

      def time_now
        Time.now.strftime('%Y-%m-%d')
      end

      def stdout?
        ENV['RAILS_LOG_TO_STDOUT'].present?
      end

      def set_divider(params)
        if params[:date_range].blank? || params[:date_range][:divider].blank?
          100
        else
          params[:date_range][:divider]
        end
      end

      def file_active?(name, params)
        'active' if params[:log_file] == name
      end

      def page_active?(index, params)
        'active' if params[:page].to_i == index
      end

      def parse_parameters(line)
        parameters = line[line.index('Parameters:') + 12..line.length]
        hash = begin
          JSON.parse parameters.gsub('=>', ':')
        rescue StandardError
          nil
        end
        return line if hash.nil?

        h = begin
          hash.reduce('<strong> Parameters: </strong> <br/> ') do |memo, (k, v)|
            memo += "<strong> #{k}: </strong> #{v}, "
          end
        rescue StandardError
          nil
        end

        begin
          h.html_safe
        rescue StandardError
          nil
        end
      end
    end
  end
end
