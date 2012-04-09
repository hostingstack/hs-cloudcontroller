xml.instruct!
xml.response do
  xml.status do
    xml.success do
      xml.text! @status.to_s
    end
  end
  xml.data do
    xml.users do
      @users.each do |u|
        xml.user(:userid=> u.id, :name => u.name, :plan => u.plan_id, :email => u.email, :state => u.state)
      end
    end
  end
end
