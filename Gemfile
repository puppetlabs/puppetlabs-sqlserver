source ENV['GEM_SOURCE'] || 'https://rubygems.org'

def location_for(place, fake_version = nil)
  if place =~ /^(git:[^#]*)#(.*)/
    [fake_version, {:git => $1, :branch => $2, :require => false}].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', {:path => File.expand_path($1), :require => false}]
  else
    [place, {:require => false}]
  end
end

group :development, :test do
  gem 'nokogiri'
  gem 'mime-types', '<2.0',     :require => false
  gem 'rake',                   :require => false
  gem 'rspec-puppet',           :require => false
  gem 'puppetlabs_spec_helper', :require => false
  gem 'puppet-lint',            :require => false
  gem 'simplecov',              :require => false
  gem 'yard',                   :require => false
  gem 'pry',                    :require => false
end

beaker_version = ENV['BEAKER_VERSION']
beaker_rspec_version = ENV['BEAKER_RSPEC_VERSION'] || '~> 5.0'
group :system_tests do
  if beaker_version
    gem 'beaker',     *location_for(beaker_version)
  end
  gem 'beaker-rspec', *location_for(beaker_rspec_version)
  gem 'specinfra',    '~> 2.0', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion,  :require => false
else
  gem 'puppet', '~> 3.7', :require => false
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
# vim:ft=ruby
