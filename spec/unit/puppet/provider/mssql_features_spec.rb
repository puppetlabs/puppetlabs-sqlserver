require 'spec_helper'
require 'rspec'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql_spec_helper.rb'))

# require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql_install_context.rb'))

provider_class = Puppet::Type.type(:mssql_features).provider(:mssql)

RSpec.describe provider_class do
  subject { provider_class }

  shared_examples 'create' do |args, munged_args = {}|
    it {
      @resource = Puppet::Type::Mssql_features.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(subject)

      executed_args = args.merge(munged_args)
      Puppet::Util.stubs(:which).with("#{executed_args[:source]}/setup.exe").returns("#{executed_args[:source]}/setup.exe")
      Puppet::Util::Execution.stubs(:execute).with(
          ["#{executed_args[:source]}/setup.exe",
           "/ACTION=install",
           '/Q',
           '/IACCEPTSQLSERVERLICENSETERMS',
           "/FEATURES=#{executed_args[:features].join(',')}",
          ]).returns(0)
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

  context 'it should expand the superset for features' do
    include_context 'features'
    @feature_params[:features] = %w(Tools)
    munged = {:features => %w(ADV_SSMS Conn SSMS)}
    it_should_behave_like 'create', @feature_params, munged
  end

  shared_examples 'features=' do |args|
    it {
      @resource = Puppet::Type::Mssql_features.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(subject)

      stub_source_which_call args[:source]

      if !feature_remove.empty?
        stub_remove_features(args[:source], feature_remove)
      end
      if !feature_add.empty?
        stub_add_features(args[:source], feature_add)
      end

      @provider.create
    }
  end

  shared_examples 'fail on' do |feature_params|
    it {
      expect {
        @resource = Puppet::Type::Mssql_features.new(feature_params)
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
end
