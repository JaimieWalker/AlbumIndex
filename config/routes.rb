Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/resource', to: "search#resource"
  get '/show', to: "search#show"
  get '/random', to: "search#random"

  root to: 'application#index#index'
  get "*path" => "application#index", format: false
end
