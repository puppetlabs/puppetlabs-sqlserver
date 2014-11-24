require 'rspec'
require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/mssql/server_helper'))

RSpec.describe PuppetX::Mssql::ServerHelper do
  let(:subject) { PuppetX::Mssql::ServerHelper }

  shared_examples 'when calling with' do |user, should_be_bool|
    it "with #{user} should return #{should_be_bool}" do
      subject.stubs(:lookupvar).with('hostname').returns('mybox')
      subject.is_domain_user?(user, 'mybox').should(eq(should_be_bool))
    end
  end

  shared_examples 'translate_features' do
    it {
      expect(PuppetX::Mssql::ServerHelper.translate_features(features)).to eq(translated)
    }
  end

  describe 'features parser' do
    {:AS => 'Analysis Services',
     :RS => 'Reporting Services - Native',
     :SQLEngine => 'Database Engine Services',
     :Replication => 'SQL Server Replication',
     :FullText => 'Full-Text and Semantic Extractions for Search',
     :DQ => 'Data Quality Services',
     :BC => 'Client Tools Backwards Compatibility',
     :SSMS => 'Management Tools - Basic',
     :ADV_SSMS => 'Management Tools - Complete',
     :Conn => 'Client Tools Connectivity',
     :SDK => 'Client Tools SDK',
     :IS => 'Integration Services',
     :MDS => 'Master Data Services'}.each do |k, v|
      it_behaves_like 'translate_features' do
        let(:features) { [v] }
        let(:translated) { [k.to_s] }
      end
    end
  end
  describe 'when calling with a local user' do
    ['mysillyuser', 'mybox\localuser'].each do |user|
      it_should_behave_like 'when calling with', user, false
    end
  end

  describe 'when calling with a system account' do
    ['NT Authority\IISUSR', 'NT Service\ManiacUser', 'nt service\mixMaxCase'].each do |user|
      it_should_behave_like 'when calling with', user, false
    end
  end

  describe 'when calling with a domain account' do
    it_should_behave_like 'when calling with', 'nexus\user', true
  end
end
