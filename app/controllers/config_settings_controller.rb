class ConfigSettingsController < ApplicationController
  before_filter :authenticate_user!
  def index
  end

  def update
    @setting = ConfigSetting.find params[:id]

    @setting.update_attributes(params[:config_setting])
    @setting.save!

    redirect_to :action=>:index
  end
end
