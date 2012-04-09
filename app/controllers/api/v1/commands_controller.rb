## @model Command
class Api::V1::CommandsController < Api::V1::ApiController
  inherit_resources
  respond_to :xml
  belongs_to :app, :finder => :find_by_name!, :param => :app_id
  has_scope :scoped_by_id, :as => :id
end
