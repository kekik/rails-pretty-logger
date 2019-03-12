module Rails
  module Pretty
    module Logger
      module ApplicationHelper

        def modify_name(name)
          return "#{name [-13..-10]}/#{name[-9..-8]}/#{name[-7..-6]} : #{name[-4..-1]}"
        end

      end
    end
  end
end
