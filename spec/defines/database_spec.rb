require 'spec_helper'

describe 'mssql::database', :type => :define do
  let(:title) { 'myTitle' }
  let(:params) { {
      :db_name => 'myTestDb',
      :instance => 'MSSQLSERVER',
  } }

  context 'Minimal Params' do
    it 'it should compile' do
      should contain_mssql_tsql('database-MSSQLSERVER-myTestDb')
    end
  end

  context 'Providing log filespec' do
    it 'should compile with valid log on params' do
      params.merge!(log_filename: "c:/test/logfile.ldf")
      params.merge!(log_name: "myCrazyLog")
      should contain_mssql_tsql('database-MSSQLSERVER-myTestDb')
    end
  end


end
