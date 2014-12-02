require 'spec_helper'

RSpec.describe Puppet::Type.type(:sqlserver_features) do
  shared_context 'features' do
    let(:params) { {
        :name => 'Base features',
        :source => 'C:\myinstallexecs',
        :features => %w(BC SSMS)
    } }
    let(:additional_params) { {} }
    let(:error_class) { Puppet::Error }
    let(:error_messages) {}

    shared_examples 'validation' do

    end

    shared_examples 'features fail validation' do
      it {
        params.merge!(additional_params)
        expect {
          subject = Puppet::Type.type(:sqlserver_features).new(params)
          subject.stubs(:lookupvar).with('hostname').returns('machineCrazyName')
        }.to raise_error(error_class) { |e|
          Array[error_messages].each do |message|
            expect(e.message).to match(/#{message}/)
          end
        }
      }
    end
  end
  describe 'test is_svc_account fails fast' do
    include_context 'features'
    it_should_behave_like 'features fail validation' do
      let(:additional_params) { {:features => %w(ADV_SSMS IS SSMS Conn), :is_svc_account => 'machineCrazyName\testUser'} }
      let(:error_messages) { 'is_svc_password required when using domain account' }
    end
  end
end
