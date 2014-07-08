require 'simplecov'
require 'rspec'
require 'rspec'

SimpleCov.start do
  add_filter "/spec/"
end
require 'puppetlabs_spec_helper/module_spec_helper'
