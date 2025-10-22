Rails.application.routes.draw do
  resources :users
  resources :categories
  resources :products do
    resources :comments
    resources :ratings
  end

  resources :carts do
    resources :line_items, only: [ :create, :destroy, :update ]
  end

  resources :orders do
    resources :line_items, only: [ :index ]
  end

  resources :line_items, only: [ :show ]
  get "up" => "rails/health#show", as: :rails_health_check

  get "posts/index"
  root "posts#index"
end
