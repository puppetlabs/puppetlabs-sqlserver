require 'spec_helper_acceptance'

skip_platform = false
skip_platform = true unless SUPPORTED_PLATFORMS.any?{ |up| fact('osfamily') == up}

describe 'Acceptance test', :unless => skip_platform do
  instance_name = 'ballmer'
  context 'MS-SAL installation and verification' do
    it 'Should appy the manifest without error' do
      pp = <<-EOS
      mssql_instance{ '#{instance_name}':
        ensure => present,
        source => #{@@SQL_2012_drive},
      }
      EOS

      apply_manifest(pp, :catch_failures => true, :acceptable_exit_codes => [0,2])
    end
    it 'Should be doing MS-SQL stuff' do
      #validation goes here
      true.should be(true)
    end
    #context 'teardown the test, uninstall ms-sql' do
      #this method is located in spec/acceptance/files/teardown.rb
      #uninstall_instance(instance_name)
    #end
  end
end
