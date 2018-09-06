require 'rspec'
require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/sql_connection'))

RSpec.describe PuppetX::Sqlserver::SqlConnection do
  let(:subject) { PuppetX::Sqlserver::SqlConnection.new }
  let(:config) { {:admin_user => 'sa', :admin_pass => 'Pupp3t1@', :instance_name => 'MSSQLSERVER'} }

  def stub_connection
    @connection = mock()
    error_mock = mock()
    error_mock.stubs(:count).returns(0)

    subject.stubs(:create_connection).returns(@connection)
    @connection.stubs(:State).returns(PuppetX::Sqlserver::CONNECTION_CLOSED)
    @connection.stubs(:Errors).returns(error_mock)
    subject.stubs(:win32_exception).returns(Exception)
  end

  describe 'open_and_run_command' do
    context 'command execution' do
      before :each do
        stub_connection
        @connection.stubs(:Open).with('Provider=SQLNCLI11;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;User ID=sa;Password=Pupp3t1@')
      end
      it 'should not raise an error but populate has_errors with message' do
        @connection.Errors.stubs(:count).returns(2)
        @connection.expects(:Errors).with(0).returns(stub( { :Description => "SQL Error in Connection" }))
        @connection.expects(:Errors).with(1).returns(stub( { :Description => "Rowdy Roddy Piper" }))
        expect {
          result = subject.open_and_run_command('whacka whacka whacka', config)
          expect(result.exitstatus).to eq(1)
          expect(result.error_message).to eq("SQL Error in Connection\nRowdy Roddy Piper")
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

      context 'Use default authentication' do
        it 'should defaul to SQL_LOGIN if admin_login_type is not set' do
          @connection.expects(:Open).with('Provider=SQLNCLI11;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;User ID=sa;Password=Pupp3t1@')
          subject.open_and_run_command('query', {:admin_user => 'sa', :admin_pass => 'Pupp3t1@' })
        end
      end

      context 'SQL Server based authentication' do
        it 'should result with error if set admin_user is not set' do
          @connection.expects(:Open).never
          expect {
            result = subject.open_and_run_command('query', { :admin_pass => 'Pupp3t1@', :admin_login_type => 'SQL_LOGIN' })
            expect(result.exitstatus).to eq(1)
          }.to_not raise_error(Exception)
        end

        it 'should result with error if set admin_pass is not set' do
          @connection.expects(:Open).never
          expect {
            result = subject.open_and_run_command('query', {:admin_user => 'sa', :admin_login_type => 'SQL_LOGIN' })
            expect(result.exitstatus).to eq(1)
          }.to_not raise_error(Exception)
        end

        it 'should not add the default instance of MSSQLSERVER to connection string' do
          @connection.expects(:Open).with('Provider=SQLNCLI11;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;User ID=sa;Password=Pupp3t1@')
          subject.open_and_run_command('query', {:admin_user => 'sa', :admin_pass => 'Pupp3t1@', :instance_name => 'MSSQLSERVER'})
        end
        it 'should add a non default instance to connection string' do
          @connection.expects(:Open).with('Provider=SQLNCLI11;Initial Catalog=master;Application Name=Puppet;Data Source=.\\LOGGING;DataTypeComptibility=80;User ID=sa;Password=Pupp3t1@')
          subject.open_and_run_command('query', {:admin_user => 'sa', :admin_pass => 'Pupp3t1@', :instance_name => 'LOGGING'})
        end
      end

      context 'Windows based authentication' do
        it 'should result with error if set admin_user is set' do
          @connection.expects(:Open).never
          expect {
            result = subject.open_and_run_command('query', {:admin_user => 'sa', :admin_pass => '', :admin_login_type => 'WINDOWS_LOGIN'})
            expect(result.exitstatus).to eq(1)
          }.to_not raise_error(Exception)
        end

        it 'should result with error if set admin_pass is set' do
          @connection.expects(:Open).never
          expect {
            result = subject.open_and_run_command('query', {:admin_user => '', :admin_pass => 'Pupp3t1@', :admin_login_type => 'WINDOWS_LOGIN'})
            expect(result.exitstatus).to eq(1)
          }.to_not raise_error(Exception)
        end

        it 'should add integrated security to the connection string if admin and password are empty' do
          @connection.expects(:Open).with('Provider=SQLNCLI11;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;Integrated Security=SSPI')
          subject.open_and_run_command('query', {:admin_user => '', :admin_pass => '', :admin_login_type => 'WINDOWS_LOGIN'})
        end

        it 'should add integrated security to the connection string if admin and password are not defined' do
          @connection.expects(:Open).with('Provider=SQLNCLI11;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;Integrated Security=SSPI')
          subject.open_and_run_command('query', { :admin_login_type => 'WINDOWS_LOGIN' })
        end
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
        stub_connection
        @connection.Errors.stubs(:count).returns(1)
        @connection.Errors.stubs(:Description).returns("SQL Error in Connection")
        @connection.stubs(:Execute).raises(Exception)
        subject.expects(:open).with({:admin_user => 'sa', :admin_pass => 'Pupp3t1@', :instance_name => 'MSSQLSERVER'})
        subject.expects(:close).once
        
        result = subject.open_and_run_command('SELECT * FROM sys.databases', config)
        expect(result.exitstatus).to eq(1)
        expect(result.error_message).to eq('SQL Error in Connection')
      }
    end
    context 'open connection failure' do
      it {
        stub_connection
        err_message = "ConnectionFailed"
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
