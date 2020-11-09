require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  mount PgHero::Engine, at: "pghero"

  resources :nodes do
    collection do
      get :countries
      get :versions
      get :secio
      get :storm
      post :report
    end
  end
  root to: 'nodes#overview'
end
