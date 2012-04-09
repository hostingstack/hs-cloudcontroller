## A DeploymentInstall represents the connection between the Deployment and the Servers it is installed on
class Api::V1::DeploymentInstallsController < Api::V1::ApiController
  inherit_resources
  respond_to :xml

  belongs_to :user, :optional => true
  belongs_to :app
  belongs_to :deployment
end
