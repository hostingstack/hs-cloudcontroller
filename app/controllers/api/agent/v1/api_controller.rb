class Api::Agent::V1::ApiController < ActionController::Base
  before_filter :authenticate

  protected

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == HS_CONFIG['agent_api_user'] && password == HS_CONFIG['agent_api_password']
    end
  end
end
