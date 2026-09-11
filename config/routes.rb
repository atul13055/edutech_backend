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
        resources :leads, only: [ :index, :show, :create, :update, :destroy ] do
          post :convert, on: :member
          resources :follow_ups, controller: "lead_follow_ups", only: [ :index, :show, :create, :update, :destroy ]
        end
        resources :admissions, only: [ :index, :show, :create, :update, :destroy ]
        resources :fee_plans, only: [ :index, :show, :create, :update, :destroy ] do
          resources :installments, controller: "fee_installments", only: [ :index, :show, :create, :update, :destroy ]
        end
        resources :student_fee_assignments, only: [ :index, :show, :create ] do
          get :payment_summary, on: :member, to: "fee_payments#summary"
          resources :payments, controller: "fee_payments", only: [ :index ]
        end
        resources :fee_payments, only: [ :index, :show, :create ]
        resource :wallet, only: [ :show ] do
          post :credit
          post :debit
          resources :transactions, controller: "wallet_transactions", only: [ :index, :show ]
        end
      end
    end
  end
end
