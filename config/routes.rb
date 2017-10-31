require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    get 'sign_in', :to => 'users/sessions#new', :as => :new_session
    post 'sign_in', :to => 'users/session#create', :as => :session
    get 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session

    get 'link_orcid', :to => 'users/sessions#link_orcid', :as => :link_orcid_session
  end

  authenticate :user, lambda { |u| u.is_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  root :to => 'index#index'

  resources :claims
  resources :docs, :only => [:index, :show], :constraints => { :id => /[0-z\-\.\(\)]+/ }
  resources :heartbeat, only: [:index]
  resources :members
  resources :people, only: [:show, :index]
  resources :services
  resources :status, :only => [:index]
  resources :tags
  resources :users

  namespace :api, defaults: { format: "json" } do
    scope module: :v1, constraints: ApiConstraint.new(version: 1, default: :true) do
      resources :claims
      resources :clients, only: [:show, :index], constraints: { :id => /.+/ }
      resources :members
      resources :orcid_users, only: [:show, :index], path: "orcid-users"
      resources :providers, only: [:show, :index]
      resources :random, only: [:index]
      resources :roles, only: [:show, :index]
      resources :services
      resources :status, only: [:index]
      resources :tags
      resources :funders
      resources :users do
        resources :claims
      end
    end
  end
end
