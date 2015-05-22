require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'sql_testing_helpers'

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

FUTURE_PARSER = ENV['FUTURE_PARSER'] == 'true' || false

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  is_foss = (ENV['IS_PE'] == 'no' || ENV['IS_PE'] == 'false') ? true : false
  if hosts.first.is_pe? && !is_foss
    install_pe
  else
    version = ENV['PUPPET_VERSION'] || '3.7.4'
    download_url = ENV['WIN_DOWNLOAD_URL'] || 'http://downloads.puppetlabs.com/windows/'
    hosts.each do |host|
      if host['platform'] =~ /windows/i
        install_puppet_from_msi(host,
                                {
                                  :win_download_url => download_url,
                                  :version => version,
                                  :install_32 => true})
      end
    end
  end

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
    %w(puppetlabs/stdlib puppetlabs/acl cyberious/pget puppetlabs/reboot puppetlabs/registry).each do |dep|
      on agent, puppet("module install #{dep}")
    end
    on agent, "git clone https://github.com/puppetlabs/puppetlabs-mount_iso #{target}/mount_iso"
    install_dev_puppet_module_on(agent, {:proj_root => proj_root, :target_module_path => "#{target}", :module_name => 'sqlserver'})
  end
end

