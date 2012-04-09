class ConfigsettingAddColorButtonBackground < ActiveRecord::Migration
  def self.up
    ConfigSetting.create :name => "cloud.branding.colors.button_background", :value => "#EBFFEB"
  end

  def self.down
  end
end
