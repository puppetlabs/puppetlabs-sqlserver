require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one('sql_host')

# database name
db_name = ('DB' + SecureRandom.hex(4)).upcase

# database user:
DB_LOGIN_USER = 'loginuser' + SecureRandom.hex(2)

describe 'sqlserver_tsql test', node: host do
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

    execute_manifest(pp) do |r|
      expect(r.stderr).not_to match(%r{Error}i)
    end
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

    it 'Run a simple tsql command via sqlserver_tsql:', tier_low: true do
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
      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end

      puts "validate the result of tsql command and table #{@table_name} should be created:"
      run_sql_query_opts = {
        query: @query,
        sql_admin_user: @admin_user,
        sql_admin_pass: @admin_pass,
        expected_row_count: 1,
      }
      run_sql_query(host, run_sql_query_opts)
    end
  end

  context 'Test sqlserver_tsql with default SQL Server based authentication', testrail: ['89024', '89025', '89026', '89068', '89069'] do
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

    it 'Run a simple tsql command via sqlserver_tsql:', tier_low: true do
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
      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end

      puts "validate the result of tsql command and table #{@table_name} should be created:"
      run_sql_query_opts = {
        query: @query,
        sql_admin_user: @admin_user,
        sql_admin_pass: @admin_pass,
        expected_row_count: 1,
      }
      run_sql_query(host, run_sql_query_opts)
    end

    it 'Run sqlserver_tsql WITH onlyif is true:', tier_low: true do
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

      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end

      puts "Validate #{@table_name} is successfully created:"
      run_sql_query_opts = {
        query: @query,
        sql_admin_user: @admin_user,
        sql_admin_pass: @admin_pass,
        expected_row_count: 1,
      }
      run_sql_query(host, run_sql_query_opts)
    end

    it 'Run sqlserver_tsql WITH onlyif is false:', tier_low: true do
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

      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end

      puts "Validate #{@table_name} is NOT created:"
      run_sql_query_opts = {
        query: @query,
        sql_admin_user: @admin_user,
        sql_admin_pass: @admin_pass,
        expected_row_count: 0,
      }
      run_sql_query(host, run_sql_query_opts)
    end

    it 'Negative test: Run tsql with invalid command:', tier_low: true do
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
      execute_manifest(pp, acceptable_exit_codes: [0, 1]) do |r|
        expect(r.stderr).to match(%r{Incorrect syntax}i)
      end
    end

    it 'Negative test: Run tsql with non-existing database:', tier_low: true do
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
      execute_manifest(pp, acceptable_exit_codes: [0, 1]) do |r|
        expect(r.stderr).to match(%r{Non-Existing-Database}i)
      end
    end
  end
end
