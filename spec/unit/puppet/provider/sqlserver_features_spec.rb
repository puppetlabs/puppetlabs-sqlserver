# frozen_string_literal: true

require 'spec_helper'
require 'rspec'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver_spec_helper.rb'))

provider_class = Puppet::Type.type(:sqlserver_features).provider(:mssql)

RSpec.describe provider_class do
  subject(:provider_class_ut) { provider_class }

  # subject { provider_class }

  let(:params) do
    {
      name: 'Base features',
      source: 'C:\myinstallexecs',
      features: ['BC', 'SSMS'],
    }
  end
  let(:additional_params) { {} }
  let(:munged_args) { {} }
  let(:additional_switches) { [] }

  shared_examples 'create' do |exit_code, warning_matcher|
    it {
      params.merge!(additional_params)
      @resource = Puppet::Type::Sqlserver_features.new(params)
      provider_class_ut = provider_class.new(@resource)

      stub_powershell_call(provider_class_ut)

      executed_args = params.merge(munged_args)
      stub_add_features(executed_args, executed_args[:features], additional_switches, exit_code || 0)
      allow(provider_class_ut).to receive(:warn).with(regexp_matches(warning_matcher)).and_return(nil) if warning_matcher
      provider_class_ut.create
    }
  end

  shared_context 'features' do
    @feature_params = {
      name: 'Base features',
      source: 'C:\myinstallexecs',
      features: ['BC', 'SSMS'],
    }
    let(:feature_remove) { [] }
    let(:feature_add) { [] }
  end

  context 'it should provide the correct command default command' do
    include_context 'features'
    it_behaves_like 'create'
  end

  context 'it should provide the correct command default command' do
    before :each do
      @file_double = Tempfile.new(['sqlconfig', '.ini'])
      allow(@file_double).to receive(:write)
      allow(@file_double).to receive(:flush)
      allow(@file_double).to receive(:close)
      allow(Tempfile).to receive(:new).with(['sqlconfig', '.ini']).and_return(@file_double)
    end
    it_behaves_like 'create' do
      let(:additional_params) { { install_switches: { 'ERRORREPORTING' => 1, 'SQLBACKUPDIR' => 'I:\DBbackup' } } }
      let(:additional_switches) { ["/ConfigurationFile=\"#{@file_double.path}\""] }
    end
  end

  # context 'it should expand the superset for features' do
  #   include_context 'features'
  #   let(:additional_params) { {:features => %w(Tools)} }
  #   let(:munged_args) { {:features => %w(ADV_SSMS BC Conn SDK SSMS)} }
  #   it_should_behave_like 'create'
  # end

  shared_examples 'features=' do |args, exit_code, warning_matcher|
    it {
      @resource = Puppet::Type::Sqlserver_features.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(provider_class_ut)
      stub_source_which_call args
      unless feature_remove.empty?
        stub_remove_features(args, feature_remove, exit_code || 0)
      end
      unless feature_add.empty?
        stub_add_features(args, feature_add, [], exit_code || 0)
      end

      # If warning_matcher supplied ensure warnings raised match, otherwise no warnings raised
      allow(@provider).to receive(:warn).with(match(warning_matcher)).and_return(nil) if warning_matcher
      allow(@provider).to receive(:warn).with(anything) unless warning_matcher
      @provider.create
    }
  end

  shared_examples 'fail on' do |feature_params|
    it {
      expect {
        @resource = Puppet::Type::Sqlserver_features.new(feature_params)
        @provider = provider_class.new(@resource)

        stub_powershell_call(provider_class_ut)

        stub_source_which_call feature_params[:source]

        @provider.create
      }.to raise_error Puppet::ResourceError
    }
  end

  context 'it should install SSMS' do
    include_context 'features'
    @feature_params[:features] = ['SSMS']
    let(:feature_add) { ['SSMS'] }

    it_behaves_like 'features=', @feature_params
  end

  context 'it should raise warning on feature install when 1641 exit code returned' do
    include_context 'features'
    @feature_params[:features] = ['SSMS']
    let(:feature_add) { ['SSMS'] }

    it_behaves_like 'features=', @feature_params, 1641, %r{reboot initiated}i
  end

  context 'it should raise warning on feature install when 3010 exit code returned' do
    include_context 'features'
    @feature_params[:features] = ['SSMS']
    let(:feature_add) { ['SSMS'] }

    it_behaves_like 'features=', @feature_params, 3010, %r{reboot required}i
  end

  # context 'it should install the expanded tools set' do
  #   include_context 'features'
  #   @feature_params[:features] = %w(Tools)
  #   let(:feature_add) { %w(ADV_SSMS BC Conn SDK SSMS) }
  #   it_should_behave_like 'features=', @feature_params
  # end

  describe 'it should call destroy on empty array' do
    it {
      feature_params = {
        name: 'Base features',
        source: 'C:\myinstallexecs',
        features: [],
      }
      @resource = Puppet::Type::Sqlserver_features.new(feature_params)
      @provider = provider_class.new(@resource)
      allow(@provider).to receive(:current_installed_features).and_return(['SSMS', 'ADV_SSMS', 'Conn'])
      allow(Puppet::Util).to receive(:which).with("#{feature_params[:source]}/setup.exe").and_return("#{feature_params[:source]}/setup.exe")
      result = Puppet::Util::Execution::ProcessOutput.new('', 0)
      expect(Puppet::Util::Execution).to receive(:execute).with(
        ["#{feature_params[:source]}/setup.exe",
         '/ACTION=uninstall',
         '/Q',
         '/IACCEPTSQLSERVERLICENSETERMS',
         "/FEATURES=#{['SSMS', 'ADV_SSMS', 'Conn'].join(',')}"], failonfail: false
      ).and_return(result)
      @provider.create
    }
  end

  describe 'it should pass the is_credentials' do
    include_context 'features'
    @feature_params[:is_svc_account] = 'nexus/Administrator'
    @feature_params[:is_svc_password] = 'MycrazyStrongPassword'
    @feature_params[:features] << 'IS'
    let(:feature_add) { ['BC', 'IS', 'SSMS'] }

    it_behaves_like 'features=', @feature_params
    # rubocop:enable RSpec/InstanceVariable
  end
end
