require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver_install_context.rb'))

RSpec.describe Puppet::Type.type(:sqlserver_instance) do
  let(:error_class) { Puppet::Error }

  # Passing validation examples
  shared_examples 'validate' do
    it {
      @subject = Puppet::Type.type(:sqlserver_instance).new(args)
      allow(@subject).to receive(:lookupvar).with('hostname').and_return('machineCrazyName')
    }
  end

  describe 'should pass with all valid arguments' do
    it_behaves_like 'validate' do
      let(:args) { basic_args }
    end
  end

  # Failed validation examples
  shared_examples 'fail validation' do
    it 'fails with' do
      expect {
        Puppet::Type.type(:sqlserver_instance).new(args)
      }.to raise_error(error_class) { |e|
        Array[messages].each do |message|
          %r{#{message}}.match(e.message)
        end
      }
    end
  end

  describe 'features' do
    ['SQL'].each do |feature_name|
      it "should raise deprecation warning with super feature #{feature_name}" do
        args = {
          name: 'MSSQLSERVER',
          ensure: 'present',
          features: [feature_name],
        }
        expect(Puppet).to receive(:deprecation_warning).at_least(:once)
        Puppet::Type.type(:sqlserver_instance).new(args)
      end
    end
  end

  describe 'agt_svc_password required when using domain account' do
    it_behaves_like 'fail validation' do
      args = basic_args
      args.delete(:agt_svc_password)
      let(:args) { args }
      let(:messages) { 'agt_svc_password' }
    end
  end

  describe 'rs_svc_account' do
    ['/', ' [', ']', ':', ';', '|', '=', ',', '+', '*', '?', '<', '>'].each do |v|
      context "contains invalid character #{v}" do
        it_behaves_like 'fail validation' do
          args = basic_args
          args[:rs_svc_account] = "crazy#{v}User"
          let(:args) { args }
          let(:messages) { ['rs_svc_account can not contain any of the special characters,'] }
        end
      end
    end
  end

  describe 'rs_svc_password' do
    context 'when less than 8 characters long' do
      it_behaves_like 'fail validation' do
        args = basic_args
        args[:rs_svc_password] = 'hrt'
        let(:args) { args }
        let(:messages) do
          ['must be at least 8 characters long',
           'must contain uppercase letters',
           'must contain numbers',
           'must contain a special character']
        end
      end
    end
  end
end
