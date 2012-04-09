## Routes associate a domain or subdomain to the app
## @model Route
class Api::V1::RoutesController < Api::V1::ApiController
  inherit_resources
  respond_to :xml,:json

  has_scope :scoped_by_id, :as => :id
  optional_belongs_to :app, :finder => :find_by_name, :param => :app_name
  optional_belongs_to :app, :finder => :find_by_name, :param => :app_id
  


  def create
    @app = App.find_by_name!(params[:app_id])
    @route = @app.routes.create(params[:route])
    respond_with(:api, :v1, @app, @route)
  end

  def destroy
    @route = Route.find(params[:id])
    @route.destroy
    head :ok
  end

  ## Verify the reachability of the Route (via DNS)
  ## returns JSON: the route
  def verify
    r = Route.find(params[:route_id])

    r.verify_dns!

    render :json => r.attributes
  end

  ## Which DNS settings are expected
  ## Returns JSON or XML
  ## cname => [cname, (cname?)]
  ## or
  ## a => [ip, (ip?)]
  def expected_dns
    r = Route.find(params[:route_id])
    respond_to do |f|
      f.json { render :json => r.expected_dns }
      f.xml { render :xml => r.expected_dns }
    end
  end
end
