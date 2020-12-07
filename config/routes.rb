require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  mount PgHero::Engine, at: "pghero"

  get :login,  to: 'sessions#new'
  get :logout, to: 'sessions#destroy'

  scope :auth do
    match '/:provider/callback', to: 'sessions#create',  via: [:get, :post]
    match :failure,              to: 'sessions#failure', via: [:get, :post]
  end

  resources :cids do
    collection do
      get :wants
      get :recent
      get :countries
      get :versions
      get :recent_chart
    end
  end

  resources :nodes do
    collection do
      get :inactive
      get :countries
      get :versions
      get :secio
      get :storm
      get :pl
      get :wants
      get :connected
      post :report
    end
  end
  root to: 'nodes#overview'
end
