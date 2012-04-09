## An instance of a service, like a database or a memcached instance
## @model ServiceInstance
class Api::V1::ServiceInstancesController < Api::V1::ApiController
  inherit_resources
  respond_to :xml
  belongs_to :user
  optional_belongs_to :app, :finder => :find_by_name!, :param => :app_name
end
