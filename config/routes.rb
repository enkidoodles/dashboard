Rails.application.routes.draw do

  resources :teams, path_names: {
    show: ''
  }

  resources :teams, except: [:index]
  resources :branches do
    resources :teams
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
