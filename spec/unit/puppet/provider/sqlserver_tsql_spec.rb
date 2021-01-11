# frozen_string_literal: true

require 'spec_helper'
require 'mocha'

RSpec.describe Puppet::Type.type(:sqlserver_tsql).provider(:mssql) do
  subject { described_class }

  let(:config) { { admin_user: 'sa', admin_pass: 'Pupp3t1@', instance_name: 'MSSQLSERVER' } }

  def stub_open_and_run(query, config)
    sqlconn = double
    expect(sqlconn).to receive(:open_and_run_command).with(gen_query(query), config)
    expect(PuppetX::Sqlserver::SqlConnection).to receive(:new).and_return(sqlconn)
  end

  def create_sqlserver_tsql(args)
    @resource = Puppet::Type::Sqlserver_tsql.new(args)
    @provider = subject.new(@resource)
  end

  def stub_get_instance_config(config)
    expect(@provider).to receive(:get_config).and_return(config)
  end

  def gen_query(query)
    quoted_query = query.gsub('\'', '\'\'')
    <<-PP
BEGIN TRY
    DECLARE @sql_text as NVARCHAR(max);
    SET @sql_text = N'#{quoted_query}'
    EXECUTE sp_executesql @sql_text;
END TRY
BEGIN CATCH
    DECLARE @msg as VARCHAR(max);
    SELECT @msg = 'THROW CAUGHT: ' + ERROR_MESSAGE();
    THROW 51000, @msg, 10
END CATCH
    PP
  end

  context 'run with a command' do
    describe 'against non master database' do
      it {
        create_sqlserver_tsql(title: 'runme', command: 'whacka whacka', instance: 'MSSQLSERVER', database: 'myDb')
        stub_get_instance_config(config)
        stub_open_and_run('whacka whacka', config.merge(database: 'myDb'))

        @provider.run(gen_query('whacka whacka'))
      }
    end
    describe 'against default database' do
      it {
        create_sqlserver_tsql(title: 'runme', command: 'whacka whacka', instance: 'MSSQLSERVER')
        stub_get_instance_config(config)
        stub_open_and_run('whacka whacka', config.merge(database: 'master'))

        @provider.run(gen_query('whacka whacka'))
      }
    end
  end
  context 'run with onlyif' do
    describe 'against default database' do
      it {
        create_sqlserver_tsql(title: 'runme', command: 'whacka whacka', onlyif: 'fozy wozy', instance: 'MSSQLSERVER')
        stub_get_instance_config(config)
        stub_open_and_run('fozy wozy', config.merge(database: 'master'))

        @provider.run(gen_query('fozy wozy'))
      }
    end
    describe 'against non master database' do
      it {
        create_sqlserver_tsql(
          title: 'runme',
          command: 'whacka whacka',
          onlyif: 'fozy wozy',
          instance: 'MSSQLSERVER',
          database: 'myDb',
        )
        stub_get_instance_config(config)
        stub_open_and_run('fozy wozy', config.merge(database: 'myDb'))
        @provider.run(gen_query('fozy wozy'))
        # rubocop:enable RSpec/InstanceVariable
      }
    end
  end
end
