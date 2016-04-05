require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'sql_testing_helpers'
require 'beaker/puppet_install_helper'

QA_RESOURCE_ROOT = "http://int-resources.ops.puppetlabs.net/QA_resources/microsoft_sql/iso/"
SQL_2014_ISO = "SQLServer2014-x64-ENU.iso"
SQL_2012_ISO = "SQLServer2012SP1-FullSlipstream-ENU-x64.iso"
SQL_ADMIN_USER = 'sa'
SQL_ADMIN_PASS = 'Pupp3t1@'

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation
  c.before(:suite) do
    host = find_only_one('sql_host')
    base_install(host['sql_version'])
  end
end

# Install PE
run_puppet_install_helper

# Install PE License onto Master
install_pe_license(master)

unless ENV['MODULE_provision'] == 'no'
  agents.each do |agent|
    # Emit CommonProgramFiles environment variable
    program_files = agent.get_env_var('ProgramFiles').split('=')[1]
    agent.add_env_var('CommonProgramFiles', "#{program_files}\\Common Files")

    # Install Forge certs to allow for PMT installation.
    install_ca_certs(agent)

    # Install test helper modules onto agent.
    %w(puppetlabs-mount_iso cyberious-pget).each do |dep|
      on(agent, puppet("module install #{dep}"))
    end

    # Determine root path of local module source.
    proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

    # In CI install from staging forge, otherwise from local
    staging = { :module_name => 'puppetlabs-sqlserver' }
    local = { :module_name => 'sqlserver', :source => proj_root }

    # Install sqlserver dependencies.
    on(agent, puppet('module install puppetlabs-stdlib'))

    # Install sqlserver module from local source.
    # See FM-5062 for more details.
    copy_module_to(agent, local)
  end
end
