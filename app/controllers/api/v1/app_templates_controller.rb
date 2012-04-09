## An AppTemplate decides which environment your App needs
## Examples might be Rails 2, Rails 3, PHP or even preinstalled Apps like Wordpress or Redmine
## @model AppTemplate
class Api::V1::AppTemplatesController < Api::V1::ApiController
  inherit_resources
  respond_to :xml
  has_scope :template_type
end
