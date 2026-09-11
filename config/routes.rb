Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      namespace :auth do
        post "login", to: "sessions#create"
        post "refresh", to: "sessions#refresh"
        delete "logout", to: "sessions#destroy"
      end

      resources :tenants
      resources :users

      namespace :admin do
        resources :students, only: [ :index, :show, :create, :update, :destroy ]
        resources :courses, only: [ :index, :show, :create, :update, :destroy ]
        resources :batches, only: [ :index, :show, :create, :update, :destroy ] do
          resources :schedules, controller: "batch_schedules", only: [ :index, :show, :create, :update, :destroy ]
        end
        resource :wallet, only: [ :show ] do
          post :credit
          post :debit
          resources :transactions, controller: "wallet_transactions", only: [ :index, :show ]
        end
      end
    end
  end
end
