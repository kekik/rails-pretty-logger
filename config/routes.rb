Rails::Pretty::Logger::Engine.routes.draw do
  resources :dashboards do
    get :log_file, on: :collection
    post :log_file, on: :collection
  end
end
