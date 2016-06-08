require 'rspec'
require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/sql_connection'))

RSpec.describe PuppetX::Sqlserver::SqlConnection do
  let(:subject) { PuppetX::Sqlserver::SqlConnection.new }
  let(:config) { {:admin_user => 'sa', :admin_pass => 'Pupp3t1@', :instance_name => 'MSSQLSERVER'} }

  def stub_connection
    @connection = mock()
    subject.stubs(:create_connection).returns(@connection)
    @connection.stubs(:State).returns(PuppetX::Sqlserver::CONNECTION_CLOSED)
    subject.stubs(:win32_exception).returns(Exception)
  end

  describe 'open_and_run_command' do
    context 'command execution' do
      before :each do
        stub_connection
        @connection.stubs(:Open).with('Provider=SQLOLEDB.1;User ID=sa;Password=Pupp3t1@;Initial Catalog=master;Application Name=Puppet;Data Source=localhost')
      end
      it 'should not raise an error but populate has_errors with message' do
        subject.stubs(:execute).raises(Exception.new("SQL Server\n error has happened"))
        expect {
          result = subject.open_and_run_command('whacka whacka whacka', config)
          expect(result.exitstatus).to eq(1)
          expect(result.error_message).to eq('error has happened')
        }.to_not raise_error(Exception)

      end
      it 'should yield when passed a block' do
        subject.stubs(:execute).returns('results')
        subject.open_and_run_command('myquery', config) do |r|
          expect(r).to eq('results')
        end
      end
    end
    context 'closed connection' do
      before :each do
        stub_connection
        @connection.stubs(:Execute)
      end
      it 'should not add MSSQLSERVER to connection string' do
        @connection.stubs(:Open).with('Provider=SQLOLEDB.1;User ID=sa;Password=Pupp3t1@;Initial Catalog=master;Application Name=Puppet;Data Source=localhost')
        subject.open_and_run_command('query', config)
      end
      it 'should add a non default instance to connection string' do
        @connection.stubs(:Open).with('Provider=SQLOLEDB.1;User ID=superuser;Password=puppetTested;Initial Catalog=master;Application Name=Puppet;Data Source=localhost\LOGGING')
        subject.open_and_run_command('query', {:admin_user => 'superuser', :admin_pass => 'puppetTested', :instance_name => 'LOGGING'})
      end
    end
    context 'open connection' do
      it 'should not reopen an existing connection' do
        stub_connection
        @connection.expects(:open).never
        @connection.stubs(:State).returns(1) # any value other than CONNECTION_CLOSED
        @connection.expects(:Execute).with('query', nil, nil)
        subject.open_and_run_command('query', config)
      end
    end
    context 'return result with errors' do
      it {
        subject.stubs(:win32_exception).returns(Exception)
        subject.expects(:open).with({:admin_user => 'sa', :admin_pass => 'Pupp3t1@', :instance_name => 'MSSQLSERVER'})
        subject.expects(:execute).with('SELECT * FROM sys.databases').raises(Exception.new("SQL Server\ninvalid syntax provider"))
        subject.expects(:close).once
        result =
          subject.open_and_run_command('SELECT * FROM sys.databases', config)
        expect(result.exitstatus).to eq(1)
        expect(result.error_message).to eq('invalid syntax provider')
      }
    end
    context 'open connection failure' do
      it {
        stub_connection
        err_message = "SQL Server\n ConnectionFailed"
        @connection.stubs(:Open).raises(Exception.new(err_message))
        expect {
          result = subject.open_and_run_command('whacka whacka whacka', config)
          expect(result.exitstatus).to eq(1)
          expect(result.error_message).to eq 'ConnectionFailed'
        }.to_not raise_error(Exception)
      }
    end
  end
end
