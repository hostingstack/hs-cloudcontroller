class Api::V1::ApiController < ActionController::Base
  before_filter :authenticate

  # FIXME: this should be handled by each controller, turning errors into error codes, etc.
  rescue_from ActiveRecord::RecordInvalid do |e|
    render :xml => {:error => e.to_s}.to_xml(:root => 'errors'), :status => :unprocessable_entity
  end

  protected
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == HS_CONFIG['cc_api_user'] && password == HS_CONFIG['cc_api_password']
    end
  end
end
