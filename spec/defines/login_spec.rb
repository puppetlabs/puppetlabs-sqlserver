require 'spec_helper'

describe 'mssql::login', :type => :define do
  let(:title) { 'myTitle' }
  let(:params) { {
      :instance => 'MSSQLSERVER',
  } }

  context 'Minimal Params' do
    it 'it should compile' do
      should contain_mssql_tsql('mssql::login-MSSQLSERVER-myTitle')
    end
  end

end
