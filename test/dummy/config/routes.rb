Rails.application.routes.draw do
  mount Rails::Pretty::Logger::Engine => "/rails-pretty-logger"
end
