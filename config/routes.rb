require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    get 'sign_in', :to => 'devise/sessions#new', :as => :new_session
    post 'sign_in', :to => 'devise/session#create', :as => :session
    delete 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
  end

  authenticate :user, lambda { |u| u.is_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  root :to => 'index#index'

  resources :docs, :only => [:index, :show], :constraints => { :id => /[0-z\-\.\(\)]+/ }
  resources :services
  resources :users
  resources :works

  namespace :api, defaults: { format: "json" } do
    scope module: :v1, constraints: ApiConstraint.new(version: 1, default: :true) do
      resources :users
    end
  end
end
