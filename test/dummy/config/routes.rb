Rails.application.routes.draw do
  mount Rails::Pretty::Logger::Engine => "/rails-pretty-logger"

  root to: redirect("/rails-pretty-logger")
end
