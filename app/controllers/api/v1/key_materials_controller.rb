class Api::V1::KeyMaterialsController < Api::V1::ApiController
  respond_to :xml

  inherit_resources
  belongs_to :user

  has_scope :scoped_by_id, :as => :id
end
