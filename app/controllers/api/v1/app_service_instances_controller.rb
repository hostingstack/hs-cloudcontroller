## A ServiceInstance may be — for example — a Database or Memcached instance
## @model ServiceInstance
class Api::V1::AppServiceInstancesController < Api::V1::ApiController
  inherit_resources
  respond_to :xml
  belongs_to :app, :finder => :find_by_name!, :param => :app_id
end
