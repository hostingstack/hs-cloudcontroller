## Represents a domain
class Api::V1::DomainsController < Api::V1::ApiController
  inherit_resources
  respond_to :xml
  belongs_to :user, :optional => true

  has_scope :scoped_by_id, :as => :id

  custom_actions :resource => :verify

  def verify(options={})
    domain = Domain.find params[:domain_id]
    domain.verify_dns!
    render :json => domain.attributes
  end
end
