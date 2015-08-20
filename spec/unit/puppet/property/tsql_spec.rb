require 'spec_helper'

describe 'tsql' do

  before :each do
    @node = Puppet::Type.type(:sqlserver_tsql).new(:name => 'update user')
  end

  it {
    @node[:command] = 'UPDATE [my_login] SET PASSWORD = "MYSillyPassword"'
    expect(@node[:command]).to match(/BEGIN TRY/)
    expect(@node[:command]).to include('UPDATE [my_login] SET PASSWORD = "MYSillyPassword"')
  }
  it 'should munge value to have begin and end try' do
    @node[:command] = 'function foo'
    @node[:onlyif] = 'exec bar'
    expect(@node[:onlyif]).to match(/BEGIN TRY\n\s+DECLARE @sql_text as NVARCHAR\(max\);\n\s+SET @sql_text = N'exec bar'\n\s+EXECUTE sp_executesql @sql_text;\nEND TRY/)
    expect(@node[:command]).to match(/BEGIN TRY\n\s+DECLARE @sql_text as NVARCHAR\(max\);\n\s+SET @sql_text = N'function foo'\n\s+EXECUTE sp_executesql @sql_text;\nEND TRY/)
  end

  it 'should properly escape single quotes in queries' do
    @node[:command] = 'SELECT \'FOO\''
    expect(@node[:command]).to match(/SET @sql_text = N'SELECT \'\'FOO\'\'/)
  end

end
