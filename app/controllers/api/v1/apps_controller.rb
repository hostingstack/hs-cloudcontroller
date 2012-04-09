# An App is pretty self-explanatory.
class Api::V1::AppsController < Api::V1::ApiController
  inherit_resources
  respond_to :xml

  before_filter :load_app, :except => [:create, :index]
  
  belongs_to :user, :optional => true

  def create
    opts = params[:app]
    opts[:name] = App.generate_name
    @app = App.create(opts)
    respond_with(:api, :v1, @app)
  rescue ActiveRecord::RecordInvalid => e
    if e.message.downcase.include?("name has already been taken")
      retry
    end
  end
  
  def show
    respond_with(@app)
  end
  
  def destroy
    @app.destroy
    head :ok
  end

  def update
    params.each do |k,v|
      @app[k] = v if ["recipe_template"].include?(k)
      if k == "app"
        v.each do |k1,v1|
          @app[k1] = v1 if ["maximum_web_instances"].include? k1
        end
      end
    end
    @app.save
    respond_with(:api, :v1, @app)
  end
  
  ## attach a service instance from the app
  def add_service_instance
    @app.service_instances << ServiceInstance.find(params[:service_instance_id])
    respond_with(:api, :v1, @app)
  end
  
  ## detach a service instance from the app
  def remove_service_instance
    @app.service_instances.delete ServiceInstance.find(params[:service_instance_id])
    respond_with(:api, :v1, @app)
  end

  ## generate a new ssh password
  ## will be returned as xml <password>_____</password>
  def new_ssh_password
    password = @app.set_ssh_password_from_random
    @app.save!
    render :xml => {:password => password}.to_xml(:root => :password)
  end

protected
  def load_app
    @app = App.find_by_name(params[:app_id] || params[:id])
    raise ActiveRecord::RecordNotFound if @app.nil?
  end
end
