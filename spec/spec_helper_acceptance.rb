require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'acceptance/files/certs.rb'
require 'acceptance/files/teardown.rb'

install_pe

SUPPORTED_PLATFORMS = ['windows']

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do

    # install correct certs on windows agents
    agents.each do |a|

      if fact_on(a, 'osfamily') == 'windows'
        #Install certs to let PMT work on windows agents
        #Installing Geotrust CA cert
        create_remote_file(a, "geotrustglobal.pem", GEOTRUST_GLOBAL_CA)
        on(a, "chmod 644 geotrustglobal.pem")
        on(a, "cmd /c certutil -v -addstore Root `cygpath -w geotrustglobal.pem`")

        # Installing Usertrust Network CA cert
        create_remote_file(a, "usertrust-network.pem", USERTRUST_NETWORK_CA)
        on(a, "chmod 644 usertrust-network.pem")
        on(a, "cmd /c certutil -v -addstore Root `cygpath -w usertrust-network.pem`")

        # Install module
        install_dev_puppet_module(:source => proj_root, :module_name => 'microsoft-sql')

        # make manifests on agent
        sql2012 = '/cygdrive/c/sql2012.pp'
        sql2014 = '/cygdrive/c/sql2014.pp'
        create_remote_file(a, sql2012, File.read("#{proj_root}/spec/acceptance/manifests/SQL2012.pp"))
        on(a, "chmod 644 #{sql2012}")
        create_remote_file(a, sql2014, File.read("#{proj_root}/spec/acceptance/manifests/SQL2014.pp"))
        on(a, "chmod 644 #{sql2014}")

        # get all the used drive letters
        drives = on(a, 'ls /cygdrive/').stdout.split

        #install required modules
        on(a, puppet('module install puppetlabs-powershell'))
        on(a, puppet('module install puppetlabs-reboot'))

        # apply manifest to mount the iso for SQL_2012 & read the drive letters
        on(a, puppet('apply c:/sql2012.pp'))
        drives_2 = on(a, 'ls /cygdrive/').stdout.split
        @@SQL_2012_drive = drives_2 - drives

        #apply manifest to mount the iso for SQL_2014 & read the drive letters
        on(a, puppet('apply c:/sql2014.pp'))
        drives_3 = on(a, 'ls /cygdrive/').stdout.split
        @@SQL2014_drive = drives_3 - drives_2
      end

    end

  end

end
