require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet_blacksmith/rake_tasks' if Bundler.rubygems.find_name('puppet-blacksmith').any?

# These lint exclusions are in puppetlabs_spec_helper but needs a version above 0.10.3 
# Line length test is 80 chars in puppet-lint 1.1.0
PuppetLint.configuration.send('disable_80chars')
# Line length test is 140 chars in puppet-lint 2.x
PuppetLint.configuration.send('disable_140chars')


desc "Validate manifests, templates, and ruby files"
task :validate do
  Dir['manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['spec/**/*.rb', 'lib/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures/
  end
  Dir['templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end

require 'rspec/core/rake_task'
desc 'test tiering'
RSpec::Core::RakeTask.new(:test_tier) do |t|
  # Setup rspec opts
  t.rspec_opts = ['--color']

  # TEST_TIERS env variable is a comma separated list of tiers to run. e.g. low, medium, high
  if ENV['TEST_TIERS']
    test_tiers = ENV['TEST_TIERS'].split(',')
    raise 'TEST_TIERS env variable must have at least 1 tier specified. low, medium or high (comma separated).' if test_tiers.count == 0
    test_tiers.each do |tier|
      raise "#{tier} not a valid test tier." unless %w(low medium high).include?(tier)
      t.rspec_opts.push("--tag tier_#{tier}")
    end
  else
    puts 'TEST_TIERS env variable not defined. Defaulting to run all tests.'
  end

  # Implement an override for the pattern with BEAKER_PATTERN env variable.
  t.pattern = ENV['BEAKER_PATTERN'] ? ENV['BEAKER_PATTERN'] : 'spec/acceptance'
end
