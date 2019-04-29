Rails.application.routes.draw do
  # For details on the DSL available within this file, see
  # http://guides.rubyonrails.org/routing.html
  resources :books

  # [START login]
  get '/login', to: redirect('/auth/google_oauth2')
  # [END login]

  # [START sessions]
  get '/auth/google_oauth2/callback', to: 'sessions#create'

  resource :session, only: [:create, :destroy]
  # [END sessions]

  # [START user_books]
  resources :user_books, only: [:index]
  # [END user_books]

  # [START logout]
  get '/logout', to: 'sessions#destroy'
  # [END logout]

  root 'books#index'
end
