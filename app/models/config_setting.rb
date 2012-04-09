class ConfigSetting < ActiveRecord::Base
  validates_uniqueness_of :name
  validates_presence_of :name

  def value
    JSON.parse(read_attribute(:data))['v']
  end
  def value=(v)
    write_attribute(:data, {'v' => v}.to_json)
  end

  # we doubletalk like a hash
  def self.[](name)
    c = self.find_by_name(name)
    return nil if c.nil?
    c.value
  end
  def self.[]=(name, v)
    c = self.find_by_name(name)
    if c.nil?
      c = ConfigSetting.create(:name => name, :value => nil)
    end
    c.value = v
    c.save!
  end
end
