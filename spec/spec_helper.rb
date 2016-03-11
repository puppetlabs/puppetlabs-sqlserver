require 'simplecov'
require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.expect_with :rspec do |e|
    e.syntax = [:should, :expect]
  end
end

SimpleCov.start do
  add_group "Functions", "lib/puppet/parser/functions"
  add_group "Types", "lib/puppet/type/"
  add_group "Provider", "lib/puppet/provider"
  add_group "Manifests", "manifests"
  add_group "PuppetX", "lib/puppet_x/"
  add_filter "/spec/"
end

