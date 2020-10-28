Rails.application.routes.draw do
  resources :nodes do
    collection do
      get :countries
      get :versions
      get :storm
      post :report
    end
  end
  root to: 'nodes#overview'
end
