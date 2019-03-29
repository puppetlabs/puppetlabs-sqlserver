require 'beaker-pe'
require 'beaker-puppet'
require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'sql_testing_helpers'
require 'beaker/puppet_install_helper'
require 'beaker/testmode_switcher'
require 'beaker/testmode_switcher/dsl'


WIN_ISO_ROOT = "https://artifactory.delivery.puppetlabs.net/artifactory/generic__iso/iso/windows"
WIN_2012R2_ISO = "en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso"
QA_RESOURCE_ROOT = "https://artifactory.delivery.puppetlabs.net/artifactory/generic__iso/iso/SQLServer"
SQL_2019_ISO = "SQLServer2019CTP2.4-x64-ENU.iso"
SQL_2017_ISO = " SQLServer2017-x64-ENU-Dev.iso"
SQL_2016_ISO = "en_sql_server_2016_enterprise_with_service_pack_1_x64_dvd_9542382.iso"
SQL_2014_ISO = "SQLServer2014SP3-FullSlipstream-x64-ENU.iso"
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
configure_type_defaults_on(hosts)

# Install PE License onto Master, if one exists.
install_pe_license(master) unless hosts_as("master").empty?

# Determine root path of local module source.
proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
# In CI install from staging forge, otherwise from local
staging = { :module_name => 'puppetlabs-sqlserver' }
local = { :module_name => 'sqlserver', :source => proj_root }

unless ENV['MODULE_provision'] == 'no'
  hosts_as("sql_host").each do |agent|
    # Emit CommonProgramFiles environment variable
    common_program_files = agent.get_env_var('CommonProgramFiles')

    # Workarounds due to BKR-914
    #  - newline chars indicate matching more than one env var
    #  - env var key matching is very loose.  e.g. CommonProgramFiles(x86) can be returned
    common_program_files = "" if common_program_files.include?("\n")
    common_program_files = "" unless common_program_files.start_with?("CommonProgramFiles=")
    #  If the env var is not found use a workaround to inject regex into the grep call
    common_program_files = agent.get_env_var('^CommonProgramFiles=') if common_program_files == ""

    if common_program_files == ""
      program_files = agent.get_env_var('PROGRAMFILES')

      # Workarounds due to BKR-914
      #  - newline chars indicate matching more than one env var
      #  - env var key matching is very loose.  e.g. ProgramFiles(x86) can be returned
      program_files = "" if program_files.include?("\n")
      program_files = "" unless program_files.start_with?("PROGRAMFILES=")
      #  If the env var is not found use a workaround to inject regex into the grep call
      program_files = agent.get_env_var('^PROGRAMFILES=') if program_files == ""

      program_files = program_files.split('=')[1]
      agent.add_env_var('CommonProgramFiles', "#{program_files}\\Common Files")
    end

    # Install Forge certs to allow for PMT installation.
    install_ca_certs

    # Install test helper modules onto agent.
    %w(puppetlabs-mount_iso cyberious-pget).each do |dep|
      on(agent, puppet("module install #{dep}"))
    end

    # Install sqlserver dependencies.
    on(agent, puppet('module install puppetlabs-stdlib'))

    # Mount windows 2012R2 ISO to allow install of .NET 3.5 Windows Feature
    iso_opts = {
        :folder       => WIN_ISO_ROOT,
        :file         => WIN_2012R2_ISO,
        :drive_letter => 'I'
    }
    mount_iso(agent, iso_opts)

    # Install sqlserver module from local source.
    # See FM-5062 for more details.
    copy_module_to(agent, local)
  end

  hosts_as("master").each do |host|
    # Install sqlserver dependencies.
    on(host, puppet('module install puppetlabs-stdlib'))

    # Install sqlserver module from local source.
    # See FM-5062 for more details.
    local = { :module_name => 'sqlserver', :source => proj_root }
    copy_module_to(host, local)
  end
end
