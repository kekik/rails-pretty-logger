Rails::Pretty::Logger::Engine.routes.draw do

  resources :dashboards, only: [:index] do
    get :logs, on: :collection
    post :logs, on: :collection
    post :clear_logs, on: :collection
  end

  resources :hourly_logs, only: [:index] do
    get :logs, on: :collection
    post :logs, on: :collection
    post :clear_logs, on: :collection
  end
end
