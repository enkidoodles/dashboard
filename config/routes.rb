Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations" }
  
  resources :branches
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'home/index'
  root 'home#index'
  resources :users
end
