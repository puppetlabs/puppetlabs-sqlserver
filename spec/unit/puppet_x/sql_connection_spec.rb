require 'rspec'
require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/sql_connection'))

RSpec.describe PuppetX::Sqlserver::SqlConnection do
  let(:subject) { PuppetX::Sqlserver::SqlConnection }

  def stub_connection
    @connection = mock()
    @sql = subject.new
    @sql.stubs(:create_connection).returns(@connection)
    @sql.stubs(:sql_exception_class).returns(Exception)
  end

  describe 'open' do
    it 'should not add MSSQLSERVER to connection string' do
      stub_connection
      @connection.stubs(:Open).with('Provider=SQLOLEDB.1;Persist Security Info=False;User ID=sa;password=Pupp3t1@;Initial Catalog=master;Data Source=localhost;Network Library=dbmssocn')
      @sql.open('sa', 'Pupp3t1@', 'MSSQLSERVER')

    end
    it 'should add a non default instance to connection string' do
      stub_connection
      @connection.stubs(:Open).with('Provider=SQLOLEDB.1;Persist Security Info=False;User ID=superuser;password=puppetTested;Initial Catalog=master;Data Source=localhost\LOGGING;Network Library=dbmssocn')
      @sql.open('superuser', 'puppetTested', 'LOGGING')
    end
  end

  describe 'command' do
    it 'should not raise an error but populate has_errors' do
      stub_connection
      @sql.stubs(:sql_exception_class).returns(Exception)
      @sql.stubs(:execute).raises(Exception.new('error has happened'))
      expect { @sql.command('whacka whacka whacka') }.to_not raise_error(Exception)
      expect(@sql.has_errors).to eq(true)
    end
    it 'should not raise an error but populate error_message' do
      stub_connection
      @sql.stubs(:execute).raises(Exception.new('error has happened'))
      expect { @sql.command('whacka whacka whacka') }.to_not raise_error(Exception)
      expect(@sql.error_message).to eq('error has happened')
    end
    it 'should yield when passed a block' do
      stub_connection
      @sql.stubs(:execute).returns('results')
      @sql.command('myquery') do |r|
        expect(r).to eq('results')
      end
    end
  end
end
