Rails.application.routes.draw do
  root :to => 'index#index'

  resources :index, only: [:index]
  resources :heartbeat, only: [:index]

  scope module: :v2, constraints: ApiConstraint.new(version: 2, default: false) do
    resources :events
  end
  
  scope module: :v1, constraints: ApiConstraint.new(version: 1, default: :true) do
    resources :events
  end
end
