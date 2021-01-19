# frozen_string_literal: true

Rails::PrettyLogger::Engine.routes.draw do
  root to: 'dashboards#index'

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
