class Api::V1::AccessTokensController < ApplicationController
  respond_to :xml

  inherit_resources
  has_scope :scoped_by_token, :as => :token
  has_scope :scoped_by_id, :as => :id
end
