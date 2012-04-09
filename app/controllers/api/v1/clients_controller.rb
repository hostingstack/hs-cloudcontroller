class Api::V1::ClientsController < Api::V1::ApiController
  respond_to :xml

  inherit_resources

  has_scope :scoped_by_identifier, :as => :identifier
  has_scope :scoped_by_id, :as => :id
end
