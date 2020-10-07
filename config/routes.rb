Rails.application.routes.draw do
  resources :nodes do
    collection do
      get :countries
      get :storm
    end
  end
  root to: 'nodes#index'
end
