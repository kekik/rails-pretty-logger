module Rails
  module Pretty
    module Logger
      class ApplicationController < ActionController::Base
        protect_from_forgery with: :exception
      end
    end
  end
end
