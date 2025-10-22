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

  # Přidáme jednoduchou routu pro zobrazení jednoho LineItem, pokud je třeba
  resources :line_items, only: [ :show ]


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  get "posts/index"
  root "posts#index"
end
