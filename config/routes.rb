Rails.application.routes.draw do
  root :to => 'index#index'

  resources :index, only: [:index]
  resources :heartbeat, only: [:index]

  resources :events
end
