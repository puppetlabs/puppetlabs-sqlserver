# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

version = '2016' # sql_version?

# database name
db_name = ('DB' + SecureRandom.hex(4)).upcase

# database user:
DB_LOGIN_USER = 'loginuser' + SecureRandom.hex(2)

describe 'sqlserver_tsql test' do
  def ensure_sqlserver_database(db_name, _ensure_val = 'present')
    pp = <<-MANIFEST
    sqlserver::config{'MSSQLSERVER':
      admin_user   => 'sa',
      admin_pass   => 'Pupp3t1@',
    }
    sqlserver::database{'#{db_name}':
        instance => 'MSSQLSERVER',
    }
    MANIFEST
    apply_manifest(pp, catch_failures: true)
  end

  context 'Test sqlserver_tsql with Windows based authentication' do
    before(:all) do
      # Create new database
      @table_name = 'Tables_' + SecureRandom.hex(3)
      @query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"

      ensure_sqlserver_database(db_name)
    end

    after(:all) do
      # remove the newly created instance
      ensure_sqlserver_database('absent')
    end

    it 'Run a simple tsql command via sqlserver_tsql:' do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        instance_name    => 'MSSQLSERVER',
        admin_login_type => 'WINDOWS_LOGIN',
      }
      sqlserver_tsql{'testsqlserver_tsql':
        instance => 'MSSQLSERVER',
        database => '#{db_name}',
        command  => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
      }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts "validate the result of tsql command and table #{@table_name} should be created:"
      run_sql_query_opts = {
        query: @query,
        sql_admin_user: @admin_user,
        sql_admin_pass: @admin_pass,
        expected_row_count: 1,
      }
      run_sql_query(run_sql_query_opts)
    end
  end

  context 'Test sqlserver_tsql with default SQL Server based authentication' do
    before(:all) do
      # Create new database
      @table_name = 'Tables_' + SecureRandom.hex(3)
      @query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"

      ensure_sqlserver_database(db_name)
    end

    after(:all) do
      # remove the newly created instance
      ensure_sqlserver_database('absent')
    end

    it 'Run a simple tsql command via sqlserver_tsql:' do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        instance_name => 'MSSQLSERVER',
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
        instance => 'MSSQLSERVER',
        database => '#{db_name}',
        command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
      }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts "validate the result of tsql command and table #{@table_name} should be created:"
      run_sql_query_opts = {
        query: @query,
        sql_admin_user: @admin_user,
        sql_admin_pass: @admin_pass,
        expected_row_count: 1,
      }
      run_sql_query(run_sql_query_opts)
    end

    it 'Run sqlserver_tsql WITH onlyif is true:', if: version.to_i != 2016 do
      # Timeout issues with command run on Sql Server 2016. Functionality of test covered by test below.
      # Initilize a new table name:
      @table_name = 'Table_' + SecureRandom.hex(3)
      @query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
          instance_name => 'MSSQLSERVER',
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{db_name}',
          command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          onlyif => "IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES) < 10000"
      }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts "Validate #{@table_name} is successfully created:"
      run_sql_query_opts = {
        query: @query,
        sql_admin_user: @admin_user,
        sql_admin_pass: @admin_pass,
        expected_row_count: 1,
      }
      run_sql_query(run_sql_query_opts)
    end

    it 'Run sqlserver_tsql WITH onlyif is false:' do
      # Initilize a new table name:
      @table_name = 'Table_' + SecureRandom.hex(3)
      @query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
          instance_name => 'MSSQLSERVER',
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{db_name}',
          command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          onlyif => "IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES) > 10000
          THROW 5300, 'Too many tables', 10"
      }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts "Validate #{@table_name} is NOT created:"
      run_sql_query_opts = {
        query: @query,
        sql_admin_user: @admin_user,
        sql_admin_pass: @admin_pass,
        expected_row_count: 0,
      }
      run_sql_query(run_sql_query_opts)
    end

    it 'Run sqlserver_tsql WITH onlyif that does a table insert:' do
      # Initilize a new table name:
      @table_name = 'Table_' + SecureRandom.hex(3)
      @query = "USE #{db_name}; SELECT * FROM #{@table_name} WHERE id = 2;"
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
          instance_name => 'MSSQLSERVER',
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{db_name}',
          command => "INSERT #{@table_name} VALUES(2, 'name2', 'email2@domain.tld');",
          onlyif => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));
          INSERT #{@table_name} VALUES(1, 'name', 'email@domain.tld');
          THROW 5300, 'Throw to trigger second INSERT statement in command property', 10"
      }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts "Validate a row is inserted into #{@table_name} by the command:"
      run_sql_query_opts = {
        query: @query,
        sql_admin_user: @admin_user,
        sql_admin_pass: @admin_pass,
        expected_row_count: 1,
      }
      run_sql_query(run_sql_query_opts)
    end

    it 'Negative test: Run tsql with invalid command:' do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        instance_name => 'MSSQLSERVER',
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
        instance => 'MSSQLSERVER',
        database => '#{db_name}',
        command => "invalid-tsql-command",
      }
      MANIFEST
      apply_manifest(pp, expect_failures: true)
    end

    it 'Negative test: Run tsql with non-existing database:' do
      @table_name = 'Table_' + SecureRandom.hex(3)
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        instance_name => 'MSSQLSERVER',
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
        instance => 'MSSQLSERVER',
        database => 'Non-Existing-Database',
        command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
      }
      MANIFEST
      # rubocop:enable RSpec/InstanceVariable
      apply_manifest(pp, expect_failures: true)
    end
  end
end
