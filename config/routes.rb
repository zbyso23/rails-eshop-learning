Rails.application.routes.draw do
  root "products#index"

  resources :users
  resources :categories
  resources :products do
    resources :comments
    resources :ratings, only: [ :create ]
  end

  resources :carts do
    resources :line_items, only: [ :create, :destroy, :update ]
  end

  resources :orders do
    resources :line_items, only: [ :index ]
  end

  resources :line_items, only: [ :show ]
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :ratings, only: [ :index ] do
        collection do
          get :category_averages
        end
      end
    end
  end

  post "switch_user/:user_id", to: "sessions#switch_user", as: :switch_user

  # Přihlášení
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Pro development - rychlé přepínání
  if Rails.env.development?
    post "switch_user/:user_id", to: "sessions#switch_user", as: :switch_user
  end

  get "posts/index"
end
