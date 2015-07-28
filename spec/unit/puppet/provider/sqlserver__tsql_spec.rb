require 'spec_helper'
require 'mocha'


RSpec.describe Puppet::Type.type(:sqlserver_tsql).provider(:mssql) do
  subject { described_class }
  let(:config) { {:admin_user => 'sa', :admin_pass => 'Pupp3t1@', :instance_name => 'MSSQLSERVER'} }

  def stub_open_and_run(query, config)
    sqlconn = mock()
    sqlconn.expects(:open_and_run_command).with(gen_query(query), config)
    PuppetX::Sqlserver::SqlConnection.expects(:new).returns(sqlconn)
  end

  def create_sqlserver_tsql(args)
    @resource = Puppet::Type::Sqlserver_tsql.new(args)
    @provider = subject.new(@resource)
  end

  def stub_get_instance_config(config)
    @provider.expects(:get_config).returns(config)
  end

  def gen_query(query)
    <<-PP
BEGIN TRY
    #{query}
END TRY
BEGIN CATCH
    DECLARE @msg as VARCHAR(max);
    SELECT @msg = 'THROW CAUGHT: ' + ERROR_MESSAGE();
    THROW 51000, @msg, 10
END CATCH
    PP
  end

  context 'run_update' do
    describe 'against non master database' do
      it {
        create_sqlserver_tsql({:title => 'runme', :command => 'whacka whacka', :instance => 'MSSQLSERVER', :database => 'myDb'})
        stub_get_instance_config(config)
        stub_open_and_run('whacka whacka', config.merge({:database => 'myDb'}))

        @provider.run_update
      }
    end
    describe 'against default database' do
      it {
        create_sqlserver_tsql({:title => 'runme', :command => 'whacka whacka', :instance => 'MSSQLSERVER'})
        stub_get_instance_config(config)
        stub_open_and_run('whacka whacka', config.merge({:database => 'master'}))

        @provider.run_update
      }
    end
  end
  context 'run_check' do
    describe 'against default database' do
      it {
        create_sqlserver_tsql({:title => 'runme', :command => 'whacka whacka', :onlyif => 'fozy wozy', :instance => 'MSSQLSERVER'})
        stub_get_instance_config(config)
        stub_open_and_run('fozy wozy', config.merge({:database => 'master'}))

        @provider.run_check
      }
    end
    describe 'against non master database' do
      it {
        create_sqlserver_tsql(
          {:title => 'runme',
           :command => 'whacka whacka',
           :onlyif => 'fozy wozy',
           :instance => 'MSSQLSERVER',
           :database => 'myDb'})
        stub_get_instance_config(config)
        stub_open_and_run('fozy wozy', config.merge({:database => 'myDb'}))

        @provider.run_check
      }
    end
  end
end
