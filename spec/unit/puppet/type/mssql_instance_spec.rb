require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql_install_context.rb'))

RSpec.describe Puppet::Type.type(:mssql_instance) do

  # Passing validation examples
  shared_examples 'validate' do |args|
    it do
      @subject = Puppet::Type.type(:mssql_instance).new(args)
      @subject.stubs(:lookupvar).with('hostname').returns('machineCrazyName')
    end
  end

  describe 'should pass with all valid arguments' do
    include_context 'install_arguments'
    it_should_behave_like 'validate', @install_args
  end

  # Failed validation examples
  shared_examples 'fail validation' do |args, messages = ['must be set'], error_class = Puppet::Error|
    it 'should fail with' do
      expect {
        Puppet::Type.type(:mssql_instance).new(args)
      }.to raise_error(error_class) { |e|
        Array[messages].each do |message|
          /#{message}/.match(e.message)
        end
      }
    end
  end

  [:agt_svc_password].each do |property|
    context "#{property} required when using domain account" do
      include_context 'install_arguments'
      @install_args.delete(property)
      it_should_behave_like 'fail validation', @install_args, display_name
    end
  end

  context 'should fail when rs_svc_account contains an invalid character' do
    include_context 'install_arguments'
    %w(/ \ [ ] : ; | = , + * ? < > ).each do |v|
      @install_args[:rs_svc_account] = "crazy#{v}User"
      it_should_behave_like 'fail validation', @install_args, 'rs_svc_account can not contain any of the special characters,'
    end
  end

  context 'must be at least 8 characters long' do
    include_context 'install_arguments'
    @install_args[:rs_svc_password] = 'hrt'
    it_should_behave_like 'fail validation', @install_args, ['must be at least 8 characters long', 'must contain uppercase letters',
                                                             'must contain numbers',
                                                             'must contain a special character']
  end

  describe 'should expand Super Values to full set' do
    include_context 'install_arguments'
    @install_args.delete(:features)
    @install_args[:features] = %w(SQL)
    subject = Puppet::Type.type(:mssql_instance).new(@install_args)
    subject.stubs(:lookupvar).with('hostname').returns('machineCrazyName')
    it do
      subject[:features].include? "SQLENGINE"
    end

  end


end
