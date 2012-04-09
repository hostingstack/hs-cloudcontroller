class Api::V1::AuthorizationCodesController < Api::V1::ApiController
  respond_to :xml

  inherit_resources
  
  has_scope :scoped_by_token, :as => :token
  has_scope :scoped_by_id, :as => :id
end
