require 'rspec'
require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/server_helper'))

RSpec.describe PuppetX::Sqlserver::ServerHelper do
  let(:subject) { PuppetX::Sqlserver::ServerHelper }

  shared_examples 'when calling with' do |user, should_be_bool|
    it "with #{user} should return #{should_be_bool}" do
      subject.stubs(:lookupvar).with('hostname').returns('mybox')
      subject.is_domain_or_local_user?(user, 'mybox').should(eq(should_be_bool))
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
