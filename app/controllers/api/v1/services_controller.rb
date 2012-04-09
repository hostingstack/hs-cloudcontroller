require 'service.rb'

## A Service may be a Database server
class Api::V1::ServicesController < Api::V1::ApiController
  respond_to :xml
  inherit_resources

  ## params: type
  ## returns xml
  def index
    services = ("Service::" + params[:type]).constantize.get_available(:all)
    render :xml => services.to_xml(:root => :services, :except => :config)
  end

  def types
    services = Service.descendants.map{|x| x.unqualified_name}
    render :xml => services.to_xml(:root => :services)
  end
end
