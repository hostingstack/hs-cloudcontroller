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
end
