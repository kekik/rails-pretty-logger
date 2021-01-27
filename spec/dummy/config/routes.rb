# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rails::PrettyLogger::Engine => '/rails/pretty_logger'
end
