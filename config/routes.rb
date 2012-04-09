require 'resque/server'
require 'resque/status_server'

HSCloudController::Application.routes.draw do
  devise_for :user

  namespace "api" do
    namespace "v1" do
      resources :apps do
        post :deploy
        post :new_ssh_password
        post :add_service_instance
        post :remove_service_instance
        resources :routes do
          post :verify
          get :expected_dns
        end
        resources :deployments do
          post :deploy
          post :drain_status
          post :undeploy
          post :commit_staging
          resources :deployment_installs
        end
        resources :app_service_instances
        resources :commands
        resources :tasks do
          collection do
            get :supported_intervals
          end
          post :dispatch_task
          post :drain_status
        end
      end
      resources :config_settings
      resources :app_templates
      resources :domains do
        post :verify
      end
      resources :servers
      resources :services do
        collection do
          get :types
        end
      end
      resources :users do
        collection do
          get :login
        end
        resources :service_instances
        resources :key_materials
      end
    
      resources :clients
      resources :authentication_codes
      resources :refresh_tokens
      resources :access_tokens
    end

    namespace "billing" do
      namespace "v1" do
        match 'user/list', :to => 'user#list', :via => :get
        match 'user/create', :to => 'user#create', :via => :post
        match 'user/modify', :to => 'user#modify', :via => :post
        match 'user/delete', :to => 'user#delete', :via => :post
      end
    end

    namespace "agent" do
      namespace "v1" do
        match 'apps/find_ssh_instance', :to => 'apps#find_ssh_instance', :via => :post
      end
    end
  end

  resource :user_session
  resources :services, :only => [:show,:update]
  resources :cloudconfig, :controller => 'config_settings', :only => [:index,:update]
  
  authenticate :user do
    match '/_ruote' => RuoteKit::Application
    match '/_ruote/*path' => RuoteKit::Application
    mount Resque::Server.new, :at => "/resque"
  end

  root :to => "servers#index"
  match 'servers/monitor_update/:name/', :to => 'servers#monitor_update', :constraints => { :name=> /.*/ }
  match 'servers/monitor', :to => 'servers#monitor'
end
