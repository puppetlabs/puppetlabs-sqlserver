# frozen_string_literal: true

require 'rspec'
require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib/puppet_x/sqlserver/sql_connection'))

RSpec.describe PuppetX::Sqlserver::SqlConnection do
  let(:subject) { described_class.new }

  let(:config) { { admin_user: 'sa', admin_pass: 'Pupp3t1@', instance_name: 'MSSQLSERVER' } }

  def stub_connection
    @connection = double
    error_mock = double
    allow(error_mock).to receive(:count).and_return(0)

    allow(subject).to receive(:create_connection).and_return(@connection)
    allow(@connection).to receive(:State).and_return(PuppetX::Sqlserver::CONNECTION_CLOSED)
    allow(@connection).to receive(:Errors).and_return(error_mock)
    allow(subject).to receive(:win32_exception).and_return(Exception)
  end

  describe 'open_and_run_command' do
    context 'command execution' do
      before :each do
        stub_connection
        allow(@connection).to receive(:Open).with('Provider=MSOLEDBSQL;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;UID=sa;PWD=Pupp3t1@')
      end
      it 'does not raise an error but populate has_errors with message' do
        allow(@connection.Errors).to receive(:count).and_return(2)
        expect(@connection).to receive(:Errors).with(0).and_return(double(Description: 'SQL Error in Connection'))
        expect(@connection).to receive(:Errors).with(1).and_return(double(Description: 'Rowdy Roddy Piper'))
        expect {
          result = subject.open_and_run_command('whacka whacka whacka', config)
          expect(result.exitstatus).to eq(1)
          expect(result.error_message).to eq("SQL Error in Connection\nRowdy Roddy Piper")
        }.not_to raise_error(Exception)
      end

      it 'yields when passed a block' do
        allow(subject).to receive(:execute).and_return('results')
        subject.open_and_run_command('myquery', config) do |r|
          expect(r).to eq('results')
        end
      end
    end
    context 'closed connection' do
      before :each do
        stub_connection
        allow(@connection).to receive(:Execute)
      end

      context 'Use default authentication' do
        it 'defauls to SQL_LOGIN if admin_login_type is not set' do
          expect(@connection).to receive(:Open).with('Provider=MSOLEDBSQL;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;UID=sa;PWD=Pupp3t1@')
          subject.open_and_run_command('query', admin_user: 'sa', admin_pass: 'Pupp3t1@')
        end
      end

      context 'SQL Server based authentication' do
        it 'results with error if set admin_user is not set' do
          expect(@connection).to receive(:Open).never
          expect {
            result = subject.open_and_run_command('query', admin_pass: 'Pupp3t1@', admin_login_type: 'SQL_LOGIN')
            expect(result.exitstatus).to eq(1)
          }.not_to raise_error(Exception)
        end

        it 'results with error if set admin_pass is not set' do
          expect(@connection).to receive(:Open).never
          expect {
            result = subject.open_and_run_command('query', admin_user: 'sa', admin_login_type: 'SQL_LOGIN')
            expect(result.exitstatus).to eq(1)
          }.not_to raise_error(Exception)
        end

        it 'does not add the default instance of MSSQLSERVER to connection string' do
          expect(@connection).to receive(:Open).with('Provider=MSOLEDBSQL;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;UID=sa;PWD=Pupp3t1@')
          subject.open_and_run_command('query', admin_user: 'sa', admin_pass: 'Pupp3t1@', instance_name: 'MSSQLSERVER')
        end

        it 'adds a non default instance to connection string' do
          expect(@connection).to receive(:Open).with('Provider=MSOLEDBSQL;Initial Catalog=master;Application Name=Puppet;Data Source=.\\LOGGING;DataTypeComptibility=80;UID=sa;PWD=Pupp3t1@')
          subject.open_and_run_command('query', admin_user: 'sa', admin_pass: 'Pupp3t1@', instance_name: 'LOGGING')
        end
      end

      context 'Windows based authentication' do
        it 'results with error if set admin_user is set' do
          expect(@connection).to receive(:Open).never
          expect {
            result = subject.open_and_run_command('query', admin_user: 'sa', admin_pass: '', admin_login_type: 'WINDOWS_LOGIN')
            expect(result.exitstatus).to eq(1)
          }.not_to raise_error(Exception)
        end

        it 'results with error if set admin_pass is set' do
          expect(@connection).to receive(:Open).never
          expect {
            result = subject.open_and_run_command('query', admin_user: '', admin_pass: 'Pupp3t1@', admin_login_type: 'WINDOWS_LOGIN')
            expect(result.exitstatus).to eq(1)
          }.not_to raise_error(Exception)
        end

        it 'adds integrated security to the connection string if admin and password are empty' do
          expect(@connection).to receive(:Open).with('Provider=MSOLEDBSQL;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;Integrated Security=SSPI')
          subject.open_and_run_command('query', admin_user: '', admin_pass: '', admin_login_type: 'WINDOWS_LOGIN')
        end

        it 'adds integrated security to the connection string if admin and password are not defined' do
          expect(@connection).to receive(:Open).with('Provider=MSOLEDBSQL;Initial Catalog=master;Application Name=Puppet;Data Source=.;DataTypeComptibility=80;Integrated Security=SSPI')
          subject.open_and_run_command('query', admin_login_type: 'WINDOWS_LOGIN')
        end
      end
    end
    context 'open connection' do
      it 'does not reopen an existing connection' do
        stub_connection
        expect(@connection).to receive(:open).never
        allow(@connection).to receive(:State).and_return(1) # any value other than CONNECTION_CLOSED
        expect(@connection).to receive(:Execute).with('query', nil, nil)
        subject.open_and_run_command('query', config)
      end
    end
    context 'return result with errors' do
      it {
        stub_connection
        allow(@connection.Errors).to receive(:count).and_return(1)
        allow(@connection.Errors).to receive(:Description).and_return('SQL Error in Connection')
        allow(@connection).to receive(:Execute).and_raise(Exception)
        expect(subject).to receive(:open).with({ admin_user: 'sa', admin_pass: 'Pupp3t1@', instance_name: 'MSSQLSERVER' })
        expect(subject).to receive(:close).once

        result = subject.open_and_run_command('SELECT * FROM sys.databases', config)
        expect(result.exitstatus).to eq(1)
        expect(result.error_message).to eq('SQL Error in Connection')
      }
    end
    context 'open connection failure' do
      it {
        stub_connection
        err_message = 'ConnectionFailed'
        allow(@connection).to receive(:Open).and_raise(Exception.new(err_message))
        expect {
          result = subject.open_and_run_command('whacka whacka whacka', config)
          expect(result.exitstatus).to eq(1)
          expect(result.error_message).to eq 'ConnectionFailed'
        }.not_to raise_error(Exception)
      }
    end
  end
end
