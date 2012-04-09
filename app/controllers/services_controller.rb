class ServicesController < ApplicationController
  before_filter :authenticate_user!

  def show
    @service = Service.find params[:id]
  end
  def update
    @service = Service.find params[:id]
    if request.POST
      @service.info = params[:service][:info]
      @service.save!
    end
    render :template => 'services/show'
  end
end
