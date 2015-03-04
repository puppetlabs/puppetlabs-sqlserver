require 'spec_helper'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver_install_context.rb'))

provider_class = Puppet::Type.type(:sqlserver_instance).provider(:mssql)

RSpec.describe provider_class do
  subject { provider_class }
  let(:additional_install_switches) { [] }

  def stub_uninstall(args, installed_features)
    cmd_args = ["#{args[:source]}/setup.exe",
                "/ACTION=uninstall",
                '/Q',
                '/IACCEPTSQLSERVERLICENSETERMS',
                "/INSTANCENAME=#{args[:name]}",
                "/FEATURES=#{installed_features.join(',')}",]
    Puppet::Util::Execution.stubs(:execute).with(cmd_args.compact).returns(0)
  end

  shared_examples 'run' do |args, munged_values = {}|
    it {
      execute_args = args.merge(munged_values)
      @resource = Puppet::Type::Sqlserver_instance.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(subject)
      stub_source_which_call args[:source]

      cmd_args = ["#{execute_args[:source]}/setup.exe",
                  "/ACTION=install",
                  '/Q',
                  '/IACCEPTSQLSERVERLICENSETERMS',
                  "/INSTANCENAME=#{execute_args[:name]}",
                  "/FEATURES=#{execute_args[:features].join(',')}",]
      (execute_args.keys - %w(ensure loglevel features name source sql_sysadmin_accounts sql_security_mode install_switches).map(&:to_sym)).sort.collect do |key|
        cmd_args << "/#{key.to_s.gsub(/_/, '').upcase}=\"#{@resource[key]}\""
      end
      if execute_args[:sql_security_mode]
        cmd_args << "/SECURITYMODE=SQL"
      end
      cmd_args << "/SQLSYSADMINACCOUNTS=#{ Array.new(@resource[:sql_sysadmin_accounts]).collect { |account| "\"#{account}\"" }.join(' ')}"
      Puppet::Util::Execution.stubs(:execute).with(cmd_args.compact).returns(0)
      @provider.create
    }
  end
  shared_examples 'create' do
    it {
      execute_args = args.merge(munged_values)
      @resource = Puppet::Type::Sqlserver_instance.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(subject)
      stub_source_which_call args[:source]

      cmd_args = ["#{execute_args[:source]}/setup.exe",
                  "/ACTION=install",
                  '/Q',
                  '/IACCEPTSQLSERVERLICENSETERMS',
                  "/INSTANCENAME=#{execute_args[:name]}",
                  "/FEATURES=#{execute_args[:features].join(',')}",]
      (execute_args.keys - %w( ensure loglevel features name source sql_sysadmin_accounts sql_security_mode install_switches).map(&:to_sym)).sort.collect do |key|
        cmd_args << "/#{key.to_s.gsub(/_/, '').upcase}=\"#{@resource[key]}\""
      end
      if execute_args[:sql_security_mode]
        cmd_args << "/SECURITYMODE=SQL"
      end
      cmd_args << "/SQLSYSADMINACCOUNTS=#{ Array.new(@resource[:sql_sysadmin_accounts]).collect { |account| "\"#{account}\"" }.join(' ')}"
      additional_install_switches.each do |switch|
        cmd_args << switch
      end
      Puppet::Util::Execution.stubs(:execute).with(cmd_args.compact).returns(0)
      @provider.create
    }
  end


  shared_examples 'destroy' do
    it {
      @resource = Puppet::Type::Sqlserver_instance.new(args)
      @provider = provider_class.new(@resource)

      stub_source_which_call args[:source]
      @provider.expects(:current_installed_features).returns(installed_features)
      stub_uninstall args, installed_features
      @provider.destroy
    }
  end

  shared_examples 'destroy on create' do
    it {
      resource = Puppet::Type::Sqlserver_instance.new(args)
      provider = provider_class.new(resource)

      stub_source_which_call args[:source]
      provider.expects(:current_installed_features).returns(installed_features)
      stub_uninstall args, installed_features
      provider.create
    }
  end
  describe 'it should provide the correct command default command' do
    it_behaves_like 'create' do
      args = get_basic_args
      let(:args) { args }
      munged = {:features => Array.new(args[:features])}
      munged[:features].delete('SQL')
      munged[:features] += %w(DQ FullText Replication SQLEngine)
      munged[:features].sort!
      let(:munged_values) { munged }
    end
  end

  describe 'empty array should' do
    it_behaves_like 'destroy on create' do
      let(:installed_features) { %w(SQLEngine Replication) }
      let(:args) { {
        :name => 'MYSQLSERVER',
        :source => 'C:\myinstallexecs',
        :features => []
      } }
    end
  end

  describe 'it should uninstall' do
    it_behaves_like 'destroy' do
      let(:args) { {
        :name => 'MYSQLSERVER',
        :source => 'C:\myinstallexecs',
        :features => []
      } }
      let(:installed_features) { %w(SQLEngine Replication) }
    end

  end
  describe 'installed features even if provided features' do
    it_behaves_like 'destroy' do
      let(:args) { {
        :name => 'MYSQLSERVER',
        :source => 'C:\myinstallexecs',
        :features => ['SQL']
      } }
      let(:installed_features) { %w(SQLEngine Replication) }
    end
  end

  describe 'install_switches' do
    it_behaves_like 'create' do
      args = get_basic_args
      args[:install_switches] = {'ERRORREPORTING' => 1}
      let(:additional_install_switches) { ['/ERRORREPORTING=1'] }
      let(:args) { args }
      munged = {:features => Array.new(args[:features])}
      munged[:features].delete('SQL')
      munged[:features] += %w(DQ FullText Replication SQLEngine)
      munged[:features].sort!
      let(:munged_values) { munged }
    end
    it_behaves_like 'create' do
      args = get_basic_args
      args[:install_switches] = {'ERRORREPORTING' => 1, 'SQLBACKUPDIR' => 'I:\DBbackup'}
      let(:additional_install_switches) { ['/ERRORREPORTING=1', '/SQLBACKUPDIR=\'I:\DBbackup\''] }
      let(:args) { args }
      munged = {:features => Array.new(args[:features])}
      munged[:features].delete('SQL')
      munged[:features] += %w(DQ FullText Replication SQLEngine)
      munged[:features].sort!
      let(:munged_values) { munged }
    end
  end
end
