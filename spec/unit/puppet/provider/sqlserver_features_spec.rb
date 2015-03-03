require 'spec_helper'
require 'rspec'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver_spec_helper.rb'))

provider_class = Puppet::Type.type(:sqlserver_features).provider(:mssql)

RSpec.describe provider_class do
  subject { provider_class }

  shared_examples 'create' do |args, munged_args = {}, additional_switches = []|
    it {
      @resource = Puppet::Type::Sqlserver_features.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(subject)

      executed_args = args.merge(munged_args)
      stub_add_features(executed_args, executed_args[:features], additional_switches)
      @provider.create
    }
  end

  shared_context 'features' do
    @feature_params = {
      :name => 'Base features',
      :source => 'C:\myinstallexecs',
      :features => %w(BC SSMS)
    }
    let(:feature_remove) { [] }
    let(:feature_add) { [] }
  end

  context 'it should provide the correct command default command' do
    include_context 'features'
    it_should_behave_like 'create', @feature_params
  end

  context 'it should provide the correct command default command' do
    include_context 'features'
    @feature_params[:install_switches] ={'ERRORREPORTING' => 1, 'SQLBACKUPDIR' => 'I:\DBbackup'}
    additional_switches = ['/ERRORREPORTING=1', '/SQLBACKUPDIR=\'I:\DBbackup\'']
    it_should_behave_like 'create', @feature_params, {}, additional_switches
  end

  context 'it should expand the superset for features' do
    include_context 'features'
    @feature_params[:features] = %w(Tools)
    munged = {:features => %w(ADV_SSMS Conn SSMS)}
    it_should_behave_like 'create', @feature_params, munged
  end

  shared_examples 'features=' do |args|
    it {
      @resource = Puppet::Type::Sqlserver_features.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(subject)
      stub_source_which_call args
      if !feature_remove.empty?
        stub_remove_features(args, feature_remove)
      end
      if !feature_add.empty?
        stub_add_features(args, feature_add)
      end

      @provider.create
    }
  end

  shared_examples 'fail on' do |feature_params|
    it {
      expect {
        @resource = Puppet::Type::Sqlserver_features.new(feature_params)
        @provider = provider_class.new(@resource)

        stub_powershell_call(subject)

        stub_source_which_call feature_params[:source]

        @provider.create
      }.to raise_error Puppet::ResourceError

    }
  end

  context 'it should install SSMS' do
    include_context 'features'
    @feature_params[:features] = %w(SSMS)
    let(:feature_add) { %w(SSMS) }
    it_should_behave_like 'features=', @feature_params
  end

  context 'it should install the expanded tools set' do
    include_context 'features'
    @feature_params[:features] = %w(Tools)
    let(:feature_add) { %w(ADV_SSMS Conn SSMS) }
    it_should_behave_like 'features=', @feature_params
  end

  context 'it should' do
    include_context 'features'
    @feature_params[:features] = %w(Tools IS)
    @feature_params[:is_svc_account] = 'nexus/domainuser'
    # let(:feature_params) { @feature_params }
    it_should_behave_like 'fail on', @feature_params
  end
  describe 'it should call destroy on empty array' do
    it {
      feature_params = {
        :name => 'Base features',
        :source => 'C:\myinstallexecs',
        :features => []
      }
      @resource = Puppet::Type::Sqlserver_features.new(feature_params)
      @provider = provider_class.new(@resource)
      @provider.stubs(:current_installed_features).returns(%w(SSMS ADV_SSMS Conn))
      Puppet::Util.stubs(:which).with("#{feature_params[:source]}/setup.exe").returns("#{feature_params[:source]}/setup.exe")
      Puppet::Util::Execution.expects(:execute).with(
        ["#{feature_params[:source]}/setup.exe",
         "/ACTION=uninstall",
         '/Q',
         '/IACCEPTSQLSERVERLICENSETERMS',
         "/FEATURES=#{%w(SSMS ADV_SSMS Conn).join(',')}",
        ]).returns(0)
      @provider.create
    }
  end

  describe 'it should pass the is_credentials' do
    include_context 'features'
    @feature_params[:is_svc_account] = 'nexus/Administrator'
    @feature_params[:is_svc_password] = 'MycrazyStrongPassword'
    @feature_params[:features] << 'IS'
    let(:feature_add) { %w(BC IS SSMS) }
    it_should_behave_like 'features=', @feature_params
  end
end
