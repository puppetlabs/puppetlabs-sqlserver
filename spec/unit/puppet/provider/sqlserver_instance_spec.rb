# frozen_string_literal: true

require 'spec_helper'
require 'mocha'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver_install_context.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver_spec_helper.rb'))

provider_class = Puppet::Type.type(:sqlserver_instance).provider(:mssql)

RSpec.describe provider_class do
  subject(:provider_class) { provider_class }

  let(:additional_install_switches) { [] }

  let(:resourcekey_to_cmdarg) do
    {
      'agt_svc_account' => 'AGTSVCACCOUNT',
      'agt_svc_password' => 'AGTSVCPASSWORD',
      'as_svc_account' => 'ASSVCACCOUNT',
      'as_svc_password' => 'ASSVCPASSWORD',
      'pid' => 'PID',
      'rs_svc_account' => 'RSSVCACCOUNT',
      'rs_svc_password' => 'RSSVCPASSWORD',
      'polybase_svc_account' => 'PBENGSVCACCOUNT',
      'polybase_svc_password' => 'PBDMSSVCPASSWORD',
      'sa_pwd' => 'SAPWD',
      'security_mode' => 'SECURITYMODE',
      'sql_svc_account' => 'SQLSVCACCOUNT',
      'sql_svc_password' => 'SQLSVCPASSWORD',
    }
  end

  def stub_uninstall(args, installed_features, exit_code = 0)
    cmd_args = ["#{args[:source]}/setup.exe",
                '/ACTION=uninstall',
                '/Q',
                '/IACCEPTSQLSERVERLICENSETERMS',
                "/INSTANCENAME=#{args[:name]}",
                "/FEATURES=#{installed_features.join(',')}"]

    result = Puppet::Util::Execution::ProcessOutput.new('', exit_code)
    allow(Puppet::Util::Execution).to receive(:execute).with(cmd_args.compact, { failonfail: false }).and_return(result)
  end

  shared_examples 'create' do |exit_code, warning_matcher|
    it {
      execute_args = args.merge(munged_values)
      @resource = Puppet::Type::Sqlserver_instance.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(provider_class)
      stub_source_which_call args[:source]

      cmd_args = ["#{execute_args[:source]}/setup.exe",
                  '/ACTION=install',
                  '/Q',
                  '/IACCEPTSQLSERVERLICENSETERMS',
                  "/INSTANCENAME=#{execute_args[:name]}",
                  "/FEATURES=#{execute_args[:features].join(',')}",
                  '/UPDATEENABLED=False']
      (execute_args.keys - ['ensure', 'loglevel', 'features', 'name', 'source', 'sql_sysadmin_accounts', 'sql_security_mode', 'install_switches'].map(&:to_sym)).sort.map do |key|
        cmd_args << "/#{resourcekey_to_cmdarg[key.to_s]}=\"#{@resource[key]}\""
      end
      cmd_args << '/SECURITYMODE=SQL' if execute_args[:sql_security_mode]

      # Extrace the SQL Sysadmins
      admin_args = execute_args[:sql_sysadmin_accounts].map(&:to_s)
      # prepend first arg only with CLI switch
      admin_args[0] = "/SQLSYSADMINACCOUNTS=#{admin_args[0]}"
      cmd_args += admin_args

      additional_install_switches.each do |switch|
        cmd_args << switch
      end

      # If warning_matcher supplied ensure warnings raised match, otherwise no warnings raised
      allow(@provider).to receive(:warn).with(anything) unless warning_matcher

      result = Puppet::Util::Execution::ProcessOutput.new('', exit_code || 0)
      allow(Puppet::Util::Execution).to receive(:execute).with(cmd_args.compact, { failonfail: false }).and_return(result)
      @provider.create
    }
  end

  shared_examples 'create_failure' do |exit_code, error_matcher|
    it {
      execute_args = args.merge(munged_values)
      @resource = Puppet::Type::Sqlserver_instance.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(provider_class)
      stub_source_which_call args[:source]

      cmd_args = ["#{execute_args[:source]}/setup.exe",
                  '/ACTION=install',
                  '/Q',
                  '/IACCEPTSQLSERVERLICENSETERMS',
                  '/UPDATEENABLED=False',
                  "/INSTANCENAME=#{execute_args[:name]}",
                  "/FEATURES=#{execute_args[:features].join(',')}"]
      (execute_args.keys - ['ensure', 'loglevel', 'features', 'name', 'source', 'sql_sysadmin_accounts', 'sql_security_mode', 'install_switches'].map(&:to_sym)).sort.map do |key|
        cmd_args << "/#{resourcekey_to_cmdarg[key.to_s]}=\"#{@resource[key]}\""
      end
      cmd_args << '/SECURITYMODE=SQL' if execute_args[:sql_security_mode]

      # wrap each arg in doublequotes
      admin_args = execute_args[:sql_sysadmin_accounts].map { |a| "\"#{a}\"" }
      # prepend first arg only with CLI switch
      admin_args[0] = "/SQLSYSADMINACCOUNTS=#{admin_args[0]}"
      cmd_args += admin_args

      additional_install_switches.each do |switch|
        cmd_args << switch
      end

      allow(@provider).to receive(:warn).with(anything)

      result = Puppet::Util::Execution::ProcessOutput.new('', exit_code || 0)
      allow(Puppet::Util::Execution).to receive(:execute).with(cmd_args.compact, { failonfail: false }).and_return(result)
      expect { @provider.create }.to raise_error(error_matcher)
    }
  end

  shared_examples 'destroy' do |exit_code, warning_matcher|
    it {
      @resource = Puppet::Type::Sqlserver_instance.new(args)
      @provider = provider_class.new(@resource)

      stub_source_which_call args[:source]
      expect(@provider).to receive(:current_installed_features).and_return(installed_features)
      stub_uninstall args, installed_features, exit_code || 0
      allow(@provider).to receive(:warn).with(match(warning_matcher)).and_return(nil) if warning_matcher
      @provider.destroy
    }
  end

  shared_examples 'destroy on create' do
    it {
      resource = Puppet::Type::Sqlserver_instance.new(args)
      provider = provider_class.new(resource)

      stub_source_which_call args[:source]
      expect(provider).to receive(:current_installed_features).and_return(installed_features)
      stub_uninstall args, installed_features
      provider.create
    }
  end

  describe 'it should provide the correct command default command' do
    it_behaves_like 'create' do
      args = basic_args
      let(:args) { args }
      munged = { features: Array.new(args[:features]) }
      munged[:features].delete('SQL')
      munged[:features] += ['DQ', 'FullText', 'Replication', 'SQLEngine']
      munged[:features].sort!
      let(:munged_values) { munged }
    end
  end

  describe 'it should raise error if as_sysadmin_accounts is specified without AS feature' do
    it_behaves_like 'create_failure', 1, %r{as_sysadmin_accounts was specified however the AS feature was not included}i do
      args = basic_args
      args[:features] = ['SQLEngine']
      args[:as_sysadmin_accounts] = 'username'

      let(:args) { args }
      munged = { features: Array.new(args[:features]) }
      let(:munged_values) { munged }
    end
  end

  describe 'it should raise error if polybase_svc_account is specified without POLYBASE feature' do
    it_behaves_like 'create_failure', 1, %r{polybase_svc_account was specified however the POLYBASE feature was not included}i do
      args = basic_args
      args[:features] = ['SQLEngine']
      args[:polybase_svc_account] = 'username'
      args.delete(:polybase_svc_password)

      let(:args) { args }
      munged = { features: Array.new(args[:features]) }
      let(:munged_values) { munged }
    end
  end

  describe 'it should raise error if polybase_svc_password is specified without POLYBASE feature' do
    it_behaves_like 'create_failure', 1, %r{polybase_svc_password was specified however the POLYBASE feature was not included}i do
      args = basic_args
      args[:features] = ['SQLEngine']
      args.delete(:polybase_svc_account)
      args[:polybase_svc_password] = 'password'

      let(:args) { args }
      munged = { features: Array.new(args[:features]) }
      let(:munged_values) { munged }
    end
  end

  describe 'it should raise warning on install when 1641 exit code returned' do
    it_behaves_like 'create', 1641, %r{reboot initiated}i do
      args = basic_args
      let(:args) { args }
      munged = { features: Array.new(args[:features]) }
      munged[:features].delete('SQL')
      munged[:features] += ['DQ', 'FullText', 'Replication', 'SQLEngine']
      munged[:features].sort!
      let(:munged_values) { munged }
    end
  end

  describe 'it should raise warning on install when 3010 exit code returned' do
    it_behaves_like 'create', 3010, %r{reboot required}i do
      args = basic_args
      let(:args) { args }
      munged = { features: Array.new(args[:features]) }
      munged[:features].delete('SQL')
      munged[:features] += ['DQ', 'FullText', 'Replication', 'SQLEngine']
      munged[:features].sort!
      let(:munged_values) { munged }
    end
  end

  describe 'empty array should' do
    it_behaves_like 'destroy on create' do
      let(:installed_features) { ['SQLEngine', 'Replication'] }
      let(:args) do
        {
          name: 'MYSQLSERVER',
          source: 'C:\myinstallexecs',
          features: [],
        }
      end
    end
  end

  describe 'it should uninstall' do
    it_behaves_like 'destroy' do
      let(:args) do
        {
          name: 'MYSQLSERVER',
          source: 'C:\myinstallexecs',
          features: [],
        }
      end
      let(:installed_features) { ['SQLEngine', 'Replication'] }
    end
  end

  describe 'it should raise warning on uninstall when 1641 exit code returned' do
    it_behaves_like 'destroy', 1641, %r{reboot initiated}i do
      let(:args) do
        {
          name: 'MYSQLSERVER',
          source: 'C:\myinstallexecs',
          features: [],
        }
      end
      let(:installed_features) { ['SQLEngine', 'Replication'] }
    end
  end

  describe 'it should raise warning on uninstall when 3010 exit code returned' do
    it_behaves_like 'destroy', 3010, %r{reboot required}i do
      let(:args) do
        {
          name: 'MYSQLSERVER',
          source: 'C:\myinstallexecs',
          features: [],
        }
      end
      let(:installed_features) { ['SQLEngine', 'Replication'] }
    end
  end

  describe 'installed features even if provided features' do
    it_behaves_like 'destroy' do
      let(:args) do
        {
          name: 'MYSQLSERVER',
          source: 'C:\myinstallexecs',
          features: ['SQL'],
        }
      end
      let(:installed_features) { ['SQLEngine', 'Replication'] }
    end
  end

  describe 'install_switches' do
    before :each do
      @file_double = Tempfile.new(['sqlconfig', '.ini'])
      allow(@file_double).to receive(:write)
      allow(@file_double).to receive(:flush)
      allow(@file_double).to receive(:close)
      allow(Tempfile).to receive(:new).with(['sqlconfig', '.ini']).and_return(@file_double)
    end

    it_behaves_like 'create' do
      args = basic_args
      args[:install_switches] = { 'ERRORREPORTING' => 1 }
      let(:additional_install_switches) { ["/ConfigurationFile=\"#{@file_double.path}\""] }
      let(:args) { args }
      munged = { features: Array.new(args[:features]) }
      munged[:features].delete('SQL')
      munged[:features] += ['DQ', 'FullText', 'Replication', 'SQLEngine']
      munged[:features].sort!
      let(:munged_values) { munged }
    end
    it_behaves_like 'create' do
      args = basic_args
      args[:install_switches] = { 'ERRORREPORTING' => 1, 'SQLBACKUPDIR' => 'I:\DBbackup' }
      let(:additional_install_switches) { ["/ConfigurationFile=\"#{@file_double.path}\""] }
      let(:args) { args }
      munged = { features: Array.new(args[:features]) }
      munged[:features].delete('SQL')
      munged[:features] += ['DQ', 'FullText', 'Replication', 'SQLEngine']
      munged[:features].sort!
      let(:munged_values) { munged }
    end
  end
end
