xml.instruct!
xml.response do
  xml.status do
    xml.success do
      xml.text! (@status ? @status.to_s : 'OK')
    end
    if @warning
      xml.warning do
	xml.text! @warning.to_s
      end
    end
  end
  xml.debug do
    xml.text! @debug
  end if not @debug.nil?
  if not @user.nil?
    xml.data do
      xml.users do
        u = @user
        xml.user(:userid=> u.id, :name => u.name, :plan => u.plan_id, :email => u.email, :state => u.state) do
          if @password_changed
            xml.password do
              xml.text! @new_password
            end
          end
        end
      end
    end
  end
end
