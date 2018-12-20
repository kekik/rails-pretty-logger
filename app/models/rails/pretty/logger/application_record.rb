module Rails
  module Pretty
    module Logger
      class ApplicationRecord < ActiveRecord::Base
        self.abstract_class = true
      end
    end
  end
end
