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
    expect(@node[:onlyif]).to match(/BEGIN TRY\n\s+exec bar\nEND TRY/)
    expect(@node[:command]).to match(/BEGIN TRY\n\s+function foo\nEND TRY/)
  end

end
