## ConfigSettings are Keys and Values that make up the configuration of the Cloud System
class Api::V1::ConfigSettingsController < Api::V1::ApiController
  inherit_resources
  respond_to :xml, :json
  actions :index, :show
end
