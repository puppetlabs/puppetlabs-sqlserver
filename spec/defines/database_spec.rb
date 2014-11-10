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
      params.merge!({:log_filename => "c:/test/logfile.ldf"})
      params.merge!({:log_name => "myCrazyLog"})
      should contain_mssql_tsql('database-MSSQLSERVER-myTestDb').with_command(/c\:\/test\/logfile\.ldf/)
    end
  end
  context 'adding collation check' do
    it 'should compile and include collation name' do
      params.merge!({:collation_name => 'SQL_Latin1_General_CP1_CI_'})
      should contain_mssql_tsql('database-MSSQLSERVER-myTestDb').with_onlyif(/AND d\.collation_name = \'SQL_Latin1_General_CP1_CI_AS\'/)
    end
  end


end
