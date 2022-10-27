Rails.application.routes.draw do
  resources :entries
  resources :feeds do
    member do
      put "mark_read"
    end
  end

  put "/sync_feeds" => "feeds#sync"

  # Defines the root path route ("/")
  root "feeds#index"
end
