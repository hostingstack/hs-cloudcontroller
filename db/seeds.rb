hostname = `hostname -f 2> /dev/null`
hostname = `hostname` if hostname.blank?
hostname.strip!

ConfigSetting.create :name => "cloud.domain.name", :value => hostname
ConfigSetting.create :name => "cloud.name", :value => hostname
ConfigSetting.create :name => "cloud.email.sender", :value => "HostingStack <root@#{hostname}>"
ConfigSetting.create :name => "cloud.email.support", :value => "root@{hostname}"
ConfigSetting.create :name => "apps.route.builtintemplate", :value => "%s.#{hostname}"
ConfigSetting.create :name => "apps.route.builtintemplate.staging", :value => "test.%s.#{hostname}"
ConfigSetting.create :name => "apps.ssh.gateway.host", :value => "ssh.#{hostname} -p 2200"
ConfigSetting.create :name => "apps.ssh.usernametemplate.staging", :value => "test-%s"
ConfigSetting.create :name => "cloud.branding.logo", :value => "url('/images/logo_controlpanel_hostingstack.png')"
ConfigSetting.create :name => "cloud.branding.colors.highlight", :value => "#2B679A"
ConfigSetting.create :name => "cloud.branding.colors.background", :value => "white"
ConfigSetting.create :name => "cloud.branding.colors.foreground", :value => "black"
ConfigSetting.create :name => "cloud.branding.colors.action", :value => "#2B679A"
ConfigSetting.create :name => "cloud.branding.colors.button_background", :value => "#EBFFEB"
ConfigSetting.create :name => "apps.name.words", :value => [
  ['blazing', 'normal', 'abrupt', 'animated', 'beautiful', 'better', 'brief', 'bright', 'blooming', 'chilly', 'cloudy', 'cool', 'deep',
   'delightful', 'detailed', 'discreet', 'dynamic', 'eager', 'early', 'efficient', 'excited', 'fabulous', 'fantastic', 'fast', 'fearless',
   'festive', 'friendly', 'floating', 'glorious', 'glossy', 'good', 'great', 'green', 'happy', 'healthy', 'kind', 'known', 'lean', 'light',
   'massive', 'melodic', 'modern', 'nice', 'nifty', 'optimal', 'orange', 'peaceful', 'perfect', 'pretty', 'purple', 'quick', 'quiet',
   'rare', 'red', 'robust', 'smart', 'sharp', 'spicy', 'tall', 'tested', 'ultra', 'yellow', 'young', 'iced'],
  ['sky', 'flower', 'samurai', 'window', 'cloud', 'evening', 'dish', 'mountain', 'lobster', 'ruby', 'zoo', 'bus', 'cake', 'can', 'deer',
   'fact', 'answer', 'hall', 'rain', 'tomato', 'river', 'eagle', 'guru', 'cave', 'bloom', 'coral', 'coat', 'dance', 'epoch', 'division',
   'fairy', 'wizard', 'sky', 'tea', 'fire']]

Client.create! :name => "HS DeployTool", :website => "http://github.com/hostingstack/deploytool/", :identifier => "org.hostingstack.api.deploytool", :secret => "11d6b5cc70e4bc9563a3b8dd50dd34f6", :redirect_uri => "none"

AppTemplate.create! :name => "Ruby on Rails / Ruby 1.8 REE", :recipe_name => "railsree18",
                    :icon_url => "/images/apps/rails_icon.png"
template = AppTemplate.create! :name => "Ruby on Rails / Ruby 1.9.2", :recipe_name => "railsr19",
                               :icon_url => "/images/apps/rails_icon.png"
AppTemplate.create! :name => "PHP 5.3+", :recipe_name => "php53",
                    :icon_url => "/images/apps/php_icon.png"

AppTemplate.create! :name => "WordPress", :recipe_name => "php53",
                    :template_type => "application", :setup_tarball => "wordpress.zip",
                    :icon_url => "/images/apps/wordpress_icon.png",
                    :screenshot_url => "/images/apps/wordpress_screenshot.png"
AppTemplate.create! :name => "Magento", :recipe_name => "php53",
                    :template_type => "application", :setup_tarball => "magento.zip",
                    :icon_url => "/images/apps/magento_icon.png",
                    :screenshot_url => "/images/apps/magento_screenshot.png"
AppTemplate.create! :name => "Joomla!", :recipe_name => "php53",
                    :template_type => "application", :setup_tarball => "joomla.zip",
                    :icon_url => "/images/apps/joomla_icon.png",
                    :screenshot_url => "/images/apps/joomla_screenshot.png"

host = Server.create! :name => "host", :state => :active, :internal_ip => '192.168.3.3', :external_ip => '10.0.0.3'
host2 = Server.create! :name =>"host2", :state => :suspended, :internal_ip => '192.168.3.4', :external_ip => '10.0.0.4'

# One fat server!
host.services.create! :type => Service::CloudController
host.services.create! :type => Service::EnvrootFactory
host.services.create! :type => Service::UserControlpanel
host.services.create! :type => Service::CodeArchive
host.services.create! :type => Service::AppHost
#host2.services.create! :type => Service::AppHost
host.services.create! :type => Service::HttpGateway
pg = host.services.create! :type => Service::Postgresql, :info => "* **Software:** PostgreSQL 9.0\r\n* **Redundant:** No\r\n* **Backups:** Daily at 1:00 UTC", :config => {:version => "9.0"}
mysql = host.services.create! :type => Service::Mysql, :info => "* **Software:** MySQL 5.1\r\n* **Redundant:** No\r\n* **Backups:** Daily at 1:00 UTC", :config => {:version => "5.1"}
memcached = host.services.create! :type => Service::Memcached, :info => "**Software:** Memcached 1.4",
                                  :config => {:port_min => 4000, :port_max => 4999, :version => "1.4"}


user = User.create! :name => "demo1", :email => "demo1@hostingstack.org", :password => "CHANGEME", :plan_id => 0, :state => :active, :is_admin => true
user.save!

app = user.apps.create! :name => App.generate_name, :template => template, :userdata => {:screenshot_url => "/images/app-installs/2.png"}.to_json
app.service_instances << pg.service_instances.create!(:user => user)
app.service_instances << mysql.service_instances.create!(:user => user)
app.service_instances << memcached.service_instances.create!(:user => user)

crt = "-----BEGIN CERTIFICATE-----\nMIICoTCCAgqgAwIBAgIJAK6iicKWn6f8MA0GCSqGSIb3DQEBBQUAMEAxITAfBgNV\nBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEbMBkGA1UEAxMSd3d3LnNvbGlk\ncmFpbHMubmV0MB4XDTExMDkxOTEwMTU1MVoXDTExMTAxOTEwMTU1MVowQDEhMB8G\nA1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMRswGQYDVQQDExJ3d3cuc29s\naWRyYWlscy5uZXQwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAMklIgfkrc7/\nVBQBu/uKAkB4T4Jd/9j1Oz4Vgef8DRSl/dLNw3Gl+qN5Mlve8+qTKe10g3Xk4rmQ\nIS6XnwokL8PpYqpL/6Yc2qrxdK5TNZmM2JnKWYkQ8MKS14CyOacCdq98fkUpF87y\nSfrHaFlV1eggeSeBnTZmYzddMygOe/mVAgMBAAGjgaIwgZ8wHQYDVR0OBBYEFIyK\ngZQE1yNrD44Q9xSKYCgW6CLBMHAGA1UdIwRpMGeAFIyKgZQE1yNrD44Q9xSKYCgW\n6CLBoUSkQjBAMSEwHwYDVQQKExhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQxGzAZ\nBgNVBAMTEnd3dy5zb2xpZHJhaWxzLm5ldIIJAK6iicKWn6f8MAwGA1UdEwQFMAMB\nAf8wDQYJKoZIhvcNAQEFBQADgYEAIvWcTtNeJkerDK63ZBpWzG3l1SlHVIAVBHWY\nC1HfHsb0IqwOStdmM+C1s8nCT/EHjSoOGb0kBKPB2EMHcY36LInOHnISRvSXIYlR\nO+IW4AZQTM1Y74cwnrh6gR0vN3ZRditjL6PFp0ftWIpc5jCI1aROXcy9tp9s1uAT\nV6iTX5k=\n-----END CERTIFICATE-----\n"
key = "-----BEGIN RSA PRIVATE KEY-----\nMIICXAIBAAKBgQDJJSIH5K3O/1QUAbv7igJAeE+CXf/Y9Ts+FYHn/A0Upf3SzcNx\npfqjeTJb3vPqkyntdIN15OK5kCEul58KJC/D6WKqS/+mHNqq8XSuUzWZjNiZylmJ\nEPDCkteAsjmnAnavfH5FKRfO8kn6x2hZVdXoIHkngZ02ZmM3XTMoDnv5lQIDAQAB\nAoGARE3+y21ldGiSNaUNH/MSpq/0WBHxosxMDN4i2hNmob9ofWBwYTR6825hon8I\nl3zX/RHW3n8WWutNyVOlpzz4ltTFmRslJUfpkt4LnOZ3/7+sBWm6qKs9uBubV0Ii\nx4bfLIuy7VV5B06fNF7t079gFAUVzy8PzMbnAMH9DEdUw0ECQQD7qh93tapGnF0A\nAcwsM4AsnbKbRd2jQOgroYjhIPGSiqTha/PY8qDK2QKfO48VAJHe9SRS+f2KTPcp\ngFXn1lolAkEAzJw2NFMuZ09O+KfYEDLnbAjr4UfvUg1bdqSJZ7px/Me1xbgoDv/Y\nDtGkFGkUx3GfxRnQNraAx7TBRw9zpjEusQJAV7bRxO2CbZ3uJCR8PyOsFuDX8ZqG\nR3JF+X8RsDXFPOgp04/Gq+TU+h5s9YbSteU+8lDK2kjbf6qXstVSG73wKQJBAJaH\nql0ugSoiL9BB83RfbuCNY7Q2rvvntc2AWVKF2YyGBNX0mQwH75VfaF5XvKDKmCdy\nyTsnY3EJK1SzKnsvHdECQDoBr0rOR4M4yuj/9Gro5tJd+TaY7QonU8NBq1UwVx/I\nrIjF8Bd9dF2AFHq+CDTVitXWjpckaFblC7pm8QUGXWA=\n-----END RSA PRIVATE KEY-----\n"
keymaterial = user.key_materials.create! :certificate => crt, :key => key

domain = user.domains.create! :name => "example.org", :verified => true
domain.routes.create! :subdomain => "", :path => "", :app => app
domain.routes.create! :subdomain => "timesten", :path => "", :app => app
domain.routes.create! :subdomain => "www", :path => "", :app => app
domain.routes.create! :subdomain => "glockenturm", :path => "", :app => app
domain = user.domains.create! :name => "hostingstack.org", :verified => true
domain.routes.create! :subdomain => "demo", :path => "", :app => app
domain = user.domains.create! :name => "solidrails.net", :verified => true
domain.routes.create! :subdomain => "bridge42", :path => "", :app => app, :key_material => keymaterial, :https_enabled => true

user = User.create! :name => "demo2", :email => "demo2@hostingstack.org", :password => "CHANGEME", :plan_id => 0, :state => :active, :is_admin => false
user.save!

app = user.apps.create! :name => App.generate_name, :template => template, :userdata => {:screenshot_url => "/images/app-installs/2.png"}.to_json
app.service_instances << pg.service_instances.create!(:user => user)
app.service_instances << mysql.service_instances.create!(:user => user)
app.service_instances << memcached.service_instances.create!(:user => user)

domain = user.domains.create! :name => "notsosolidrails.net", :verified => true
domain.routes.create! :subdomain => "", :path => "", :app => app
domain.routes.create! :subdomain => "www", :path => "", :app => app
domain.routes.create! :subdomain => "demo", :path => "", :app => app
domain = user.domains.create! :name => "example.com", :verified => true
