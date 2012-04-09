## @model Task
## Note: this controller exposes an entire STI model chain.
class Api::V1::TasksController < Api::V1::ApiController
  inherit_resources
  respond_to :xml
  belongs_to :app, :finder => :find_by_name!, :param => :app_id
  has_scope :scoped_by_id, :as => :id
  include InheritedResourceSTIHelpers

  def dispatch_task
    object = resource
    token = object.dispatch!
    render :xml => {:token => token}.to_xml(:root => object.class.name.underscore)
  end

  def drain_status
    object = resource
    message = object.status params[:token]
    logs = object.drain_log!
    render :xml => {:message => message.to_s, :logs => logs}.to_xml(:root => object.class.name.underscore)
  end

  def supported_intervals
    render :xml => PeriodicTask.supported_intervals
  end
end
