require 'spec_helper'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql_install_context.rb'))

provider_class = Puppet::Type.type(:mssql_features).provider(:mssql)

RSpec.describe provider_class do
  subject { provider_class }

  shared_examples 'create' do |args, munged_args = {}|
    it {
      @resource = Puppet::Type::Mssql_features.new(args)
      @provider = provider_class.new(@resource)

      Puppet::Util.stubs(:which).with('powershell.exe').returns('powershell.exe')
      subject.expects(:powershell)

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

  shared_examples 'failed run' do |args, message|

  end

  RSpec.shared_context 'features' do
    @feature_params = {
        :name => 'Base features',
        :source => 'C:\myinstallexecs',
        :features => %w(BC SSMS)
    }
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

  shared_examples 'features=' do |args, orig_features = [], feature_add = [], feature_remove = []|
    it {
      @resource = Puppet::Type::Mssql_features.new(args)
      @provider = provider_class.new(@resource)

      Puppet::Util.stubs(:which).with('powershell.exe').returns('powershell.exe')
      subject.expects(:powershell)
      Puppet::Util.stubs(:which).with("#{args[:source]}/setup.exe").returns("#{args[:source]}/setup.exe")
      # subject.expects(:exists?).returns(:true)
      # subject.expects(:features).returns(orig_features)
      if !feature_remove.empty?
        Puppet::Util::Execution.stubs(:execute).with(
            ["#{args[:source]}/setup.exe",
             "/ACTION=uninstall",
             '/Q',
             '/IACCEPTSQLSERVERLICENSETERMS',
             "/FEATURES=#{feature_remove.join(',')}",
            ]).returns(0)
      end
      if !feature_add.empty?
        Puppet::Util::Execution.stubs(:execute).with(
            ["#{args[:source]}/setup.exe",
             "/ACTION=install",
             '/Q',
             '/IACCEPTSQLSERVERLICENSETERMS',
             "/FEATURES=#{feature_add.join(',')}",
            ]).returns(0)
      end
      @provider.features = args[:features]
    }
  end
  # context 'it should be run only those that differ from what is on he system' do
  #   include_context 'features'
  #   @feature_params[:features] = %w(BC Conn SSMS)
  #   it_should_behave_like 'features=', @feature_params, %w(SSMS), %w(BC Conn)
  # end

end
