require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql_install_context.rb'))

RSpec.describe Puppet::Type.type(:sqlserver_instance) do
  let(:error_class) { Puppet::Error }

  # Passing validation examples
  shared_examples 'validate' do
    it {
      @subject = Puppet::Type.type(:sqlserver_instance).new(args)
      @subject.stubs(:lookupvar).with('hostname').returns('machineCrazyName')
    }
  end

  describe 'should pass with all valid arguments' do
    it_should_behave_like 'validate' do
      let(:args) { get_basic_args }
    end
  end

  # Failed validation examples
  shared_examples 'fail validation' do #|args, messages = ['must be set'], error_class = Puppet::Error|
    it 'should fail with' do
      expect {
        Puppet::Type.type(:sqlserver_instance).new(args)
      }.to raise_error(error_class) { |e|
        Array[messages].each do |message|
          expect(e.message).to match(/#{message}/)
        end
      }
    end
  end

  describe "agt_svc_password required when using domain account" do
    it_should_behave_like 'fail validation' do
      args = get_basic_args
      args.delete(:agt_svc_password)
      let(:args) { args }
      let(:messages) { 'agt_svc_password' }
    end
  end


  describe 'should fail when rs_svc_account contains an invalid character' do
    %w(/ \ [ ] : ; | = , + * ? < > ).each do |v|
      it_should_behave_like 'fail validation' do
        args = get_basic_args
        args[:rs_svc_account] = "crazy#{v}User"
        let(:args) { args }
        let(:messages) { ['rs_svc_account can not contain any of the special characters,'] }
      end
    end
  end

  context 'must be at least 8 characters long' do
    it_behaves_like 'fail validation' do
      args = get_basic_args
      args[:rs_svc_password] = 'hrt'
      let(:args) { args }
      let(:messages) { ['must be at least 8 characters long', 'must contain uppercase letters',
                        'must contain numbers',
                        'must contain a special character'] }

    end
  end
end
