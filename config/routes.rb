Rails.application.routes.draw do

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
