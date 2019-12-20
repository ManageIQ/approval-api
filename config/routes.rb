Rails.application.routes.draw do
  # Disable PUT for now since rails sends these :update and they aren't really the same thing.
  def put(*_args)
  end

  routing_helper = Insights::API::Common::Routing.new(self)

  prefix = "api"
  if ENV["PATH_PREFIX"].present? && ENV["APP_NAME"].present?
    prefix = File.join(ENV["PATH_PREFIX"], ENV["APP_NAME"]).gsub(/^\/+|\/+$/, "")
  end

  scope :as => :api, :module => "api", :path => prefix do
    routing_helper.redirect_major_version("v1.0", prefix)

    namespace :v1x0, :path => "v1.0" do
      resources :stageaction, :only => %i(show update)

      get "/openapi.json", :to => "root#openapi"
      post "/graphql", :to => "graphql#query"

      resources :actions, :only => [:show]

      resources :requests, :only => %i(create index show) do
        resources :requests, :only => [:index]
        resources :actions, :only => %i(create index)
      end

      get "/requests/:id/content", :to => "requests#show"

      resources :workflows, :only => %i(index destroy update show)

      post '/workflows/:id/link', :to => "workflows#link", :as => 'link'
      post '/workflows/:id/unlink', :to => "workflows#unlink", :as => 'unlink'

      resources :templates, :only => %i(index show) do
        resources :workflows, :only => %i(create index)
      end
    end
  end
end
