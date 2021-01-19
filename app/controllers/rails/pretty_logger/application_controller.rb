# frozen_string_literal: true

module Rails
  module PrettyLogger
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
    end
  end
end
