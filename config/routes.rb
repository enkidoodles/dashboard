Rails.application.routes.draw do
  devise_for :users, controllers: { 
  	registrations: "registrations"
  }
  root 'branches#index'
  get 'branches/updates'
  resources :branches
end
