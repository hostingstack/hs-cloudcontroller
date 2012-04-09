# Disable Rake legacy compatibility monkey-patching
module Rake; REDUCE_COMPAT = true; end

require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

ENV["RAILS_ENV"] = ENV["RACK_ENV"] = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "production"
