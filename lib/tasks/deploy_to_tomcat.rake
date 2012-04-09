#! -*- mode: ruby -*-
task :deploy_to_tomcat do
  require 'jruby-jars'
  require 'jruby-rack'

  puts "Copying product files"
  FileUtils.rm_rf "war-out"
  FileUtils.cp_r "public", "war-out"
  FileUtils.mkdir "war-out/META-INF"
  FileUtils.mkdir "war-out/WEB-INF"
  FileUtils.cp_r "Gemfile", "war-out/WEB-INF/"
  FileUtils.cp_r "Gemfile.lock", "war-out/WEB-INF/"
  FileUtils.cp_r "bundled", "war-out/WEB-INF/"
  FileUtils.cp_r ".bundle", "war-out/WEB-INF/"
  FileUtils.cp_r "config", "war-out/WEB-INF/"
  FileUtils.cp_r "app", "war-out/WEB-INF/"
  FileUtils.cp_r "lib", "war-out/WEB-INF/"
  FileUtils.mkdir_p "war-out/WEB-INF/gems"

  puts "Installing bundler"
  ENV['GEM_HOME'] = "./war-out/WEB-INF/gems"
  ruby "-S gem environment"
  ruby "-S gem install bundler"

  puts "Copying boot jars"
  FileUtils.cp JRubyJars::core_jar_path, "war-out/WEB-INF/lib/"
  FileUtils.cp JRubyJars::stdlib_jar_path, "war-out/WEB-INF/lib/"
  FileUtils.cp JRubyJars::jruby_rack_jar_path, "war-out/WEB-INF/lib/"

  puts "Writing config files"
  File.open("war-out/META-INF/MANIFEST.MF", "w") do |f|
    f.puts "Manifest-Version: 1.0\n"
  end
  File.open("war-out/META-INF/init.rb", "w") do |f|
    f.puts <<-EOT
WARBLER_CONFIG = {"public.root"=>"/", "rails.env"=>"production", "jruby.compat.version"=>"1.9"}
ENV['GEM_HOME'] ||= $servlet_context.getRealPath('/WEB-INF/bundled/jruby/1.9/gems')
ENV['BUNDLE_WITHOUT'] = 'development:test'
ENV['BUNDLE_GEMFILE'] = 'Gemfile'

ENV['RAILS_ENV'] = 'production'
ENV['HOME'] = $servlet_context.getRealPath('/WEB-INF/')
    EOT
  end
  File.open("war-out/WEB-INF/web.xml", "w") do |f|
    f.puts <<-EOT
<!DOCTYPE web-app PUBLIC
  "-//Sun Microsystems, Inc.//DTD Web Application 2.3//EN"
  "http://java.sun.com/dtd/web-app_2_3.dtd">
<web-app>

  <context-param>
    <param-name>public.root</param-name>
    <param-value>/</param-value>
  </context-param>

  <context-param>
    <param-name>rails.env</param-name>
    <param-value>production</param-value>
  </context-param>

  <context-param>
    <param-name>jruby.compat.version</param-name>
    <param-value>1.9</param-value>
  </context-param>

  <filter>
    <filter-name>RackFilter</filter-name>
    <filter-class>org.jruby.rack.RackFilter</filter-class>
  </filter>
  <filter-mapping>
    <filter-name>RackFilter</filter-name>
    <url-pattern>/*</url-pattern>
  </filter-mapping>

  <listener>
    <listener-class>org.jruby.rack.rails.RailsServletContextListener</listener-class>
  </listener>

</web-app>
    EOT
  end

  sh "sudo rsync --delete -r ./war-out/ /var/lib/tomcat6/webapps/cc/"
end
