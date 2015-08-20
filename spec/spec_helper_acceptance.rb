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

run_puppet_install_helper

unless ENV['MODULE_provision'] == 'no'
  agents.each do |agent|
    # Emit CommonProgramFiles environment variable
    program_files = agent.get_env_var('ProgramFiles').split('=')[1]
    agent.add_env_var('CommonProgramFiles', "#{program_files}\\Common Files")

    # Install sqlserver module to agent
    result = on agent, "echo #{agent['distmoduledir']}"
    target = result.raw_output.chomp
    proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    exec_puppet = <<-EOS
    exec{'Download':
      command => 'powershell.exe -command "Invoke-WebRequest https://forgeapi.puppetlabs.com"',
      path => ['c:\\windows\\sysnative\\WindowsPowershell\\v1.0','c:\\windows\\system32\\WindowsPowershell\\v1.0'],
    }
    EOS
    apply_manifest_on(agent, exec_puppet)
    %w(puppetlabs/stdlib cyberious/pget).each do |dep|
      on agent, puppet("module install #{dep}")
    end
    on agent, "git clone https://github.com/puppetlabs/puppetlabs-mount_iso #{target}/mount_iso"

    install_ca_certs(agent)

    # in CI install from staging forge, otherwise from local
    staging = { :module_name => 'puppetlabs-sqlserver' }
    local = { :module_name => 'sqlserver', :proj_root => proj_root, :target_module_path => target }

    install_dev_puppet_module_on(agent, options[:forge_host] ? staging : local)
  end
end

