::Devise.mailer

class Devise::Mailer
  include Devise::Mailers::Helpers

  def welcome(record)
    devise_mail(record, :welcome)
  end
end
