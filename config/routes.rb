Rails.application.routes.draw do
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


  get "posts/index"
  root "posts#index"
end
