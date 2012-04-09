module ApplicationHelper
  def navigation_link_to(name, options = {}, html_options = {})
    html_options[:class] = 'current' if current_page?(options)
    link_to name, options, html_options
  end
  
  def body_classes
    classes = []
    classes << controller.controller_name
    classes << controller.action_name
    classes.join ' '
  end
end
