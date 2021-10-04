module Rails::Pretty::Logger
  module ApplicationHelper

    def modify_name(name)
      return "#{name [-13..-10]}/#{name[-9..-8]}/#{name[-7..-6]} : #{name[-4..-1]}"
    end

    def trim_name(name)
      index = name.split("/log/").last.capitalize
    end

  end
end
