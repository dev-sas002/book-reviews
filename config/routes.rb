Rails.application.routes.draw do
  # Used by the container healthcheck; deliberately outside the /api namespace
  # so that it is not part of the public resource surface.
  get '/health', to: 'health#show'

  concern :reviewable do
    resources :reviews, only: %i[create index]
  end

  namespace :api do
    resources :authors, only: %i[create index show update], concerns: :reviewable
    resources :books, only: %i[create index show update], concerns: :reviewable
    resources :users, only: %i[create index show update]
  end
end
