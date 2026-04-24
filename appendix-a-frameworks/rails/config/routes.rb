Rails.application.routes.draw do
  resources :docs,   only: [:create]
  get "/search", to: "search#index"
end
