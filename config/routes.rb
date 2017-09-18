Rails.application.routes.draw do

  resources :profiles
  require 'sidekiq/web'
  require 'sidekiq/api'
  mount Sidekiq::Web => '/sidekiq'

  root to: 'jobs#index'
  resources :jobs
  get 'jobs/status/:id' => 'jobs#status'
  get 'jobs/download/:id' => 'jobs#download'
  match "status" => proc { [200, {"Content-Type" => "text/plain"}, [Sidekiq::Queue.new.size < 100 ? "OK" : "UHOH" ]] }, via: :get
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
