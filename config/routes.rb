Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations" }
  
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'home/index'
  root 'branches#index'
  get 'branches/updates'
  resources :users
  resources :branches
  
end
