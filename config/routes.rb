Rails.application.routes.draw do
  root to: 'tasks#index'
  resource :tasks

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount ActionCable.server => '/cable'
end
