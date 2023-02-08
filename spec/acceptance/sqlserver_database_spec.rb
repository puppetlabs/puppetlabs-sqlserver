# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'securerandom'

describe 'Test sqlserver::database' do
  # Return options for run_sql_query
  def run_sql_query_opts(query, expected_row_count)
    {
      query: query,
      sql_admin_user: 'sa',
      sql_admin_pass: 'Pupp3t1@',
      expected_row_count: expected_row_count,
    }
  end

  context 'Start testing...' do
    before(:each) do
      @db_name = ('DB' + SecureRandom.hex(4)).upcase
      @table_name = 'Tables_' + SecureRandom.hex(3)
    end

    after(:each) do
      # delete created database:
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => Sensitive('sa'),
          admin_pass    => Sensitive('Pupp3t1@'),
        }
        sqlserver::database{'#{@db_name}':
          ensure  => 'absent',
        }
        sqlserver::database{'#{@db_name}-2':
          ensure  => 'absent',
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)
    end

    it 'Test Case C89019: Create a database' do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => Sensitive('sa'),
          admin_pass    => Sensitive('Pupp3t1@'),
        }
        sqlserver::database{'#{@db_name}':
        }
        sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          command => "use #{@db_name}; CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts "Validate the Database '#{@db_name}' and table '#{@table_name}' are successfully created:"
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(run_sql_query_opts(query, 1))
    end

    it 'Delete a database' do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{@db_name}':
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts "Validate the Database '#{@db_name}' exists"
      query = "SELECT database_id from sys.databases WHERE name = '#{@db_name}';"
      run_sql_query(run_sql_query_opts(query, 1))

      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{@db_name}':
          ensure => absent,
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts "Validate the Database '#{@db_name}' does not exist"
      query = "SELECT database_id from sys.databases WHERE name = '#{@db_name}';"
      run_sql_query(run_sql_query_opts(query, 0))
    end

    it 'Test Case C89076: Create database with optional collation_name' do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{@db_name}':
          collation_name => 'SQL_Estonian_CP1257_CS_AS',
        }
        sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          command => "use #{@db_name};CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts 'Validate that a table can be created in the database:'
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct collation name:"
      query = "SELECT name AS Database_Name, collation_name
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND collation_name = 'SQL_Estonian_CP1257_CS_AS';"

      run_sql_query(run_sql_query_opts(query, 1))
    end

    it 'Test Case C89077: Create database with optional compatibility' do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{@db_name}':
          compatibility => 100,
        }
        sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          command => "use #{@db_name};CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts 'Validate that a table can be created in the database:'
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct compatibility level:"
      query = "SELECT name AS Database_Name, compatibility_level
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND compatibility_level = '100';"

      run_sql_query(run_sql_query_opts(query, 1))
    end

    it 'Test Case C89078: Create database with optional containment' do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user   => 'sa',
          admin_pass   => 'Pupp3t1@',
        }
        sqlserver::sp_configure{ 'sp_config4db':
          config_name   => 'contained database authentication',
          value         => 1,
          reconfigure   => true,
          instance      => 'MSSQLSERVER',
        }
        sqlserver::database{ '#{@db_name}':
          containment => 'PARTIAL',
          require     => Sqlserver::Sp_configure['sp_config4db']
        }
        sqlserver_tsql{'testsqlserver_tsql':
            instance => 'MSSQLSERVER',
            command => "use #{@db_name};CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
            require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts 'Validate that a table can be created in the database:'
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct containment:"
      query = "SELECT name AS Database_Name, containment_desc
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND containment_desc = 'PARTIAL';"

      run_sql_query(run_sql_query_opts(query, 1))
    end

    it 'Test Case C89079: Create database with optional db_chaining' do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user   => 'sa',
          admin_pass   => 'Pupp3t1@',
        }
        sqlserver::sp_configure{ 'sp_config4db':
          config_name   => 'contained database authentication',
          value         => 1,
          reconfigure   => true,
          instance      => 'MSSQLSERVER',
        }
        sqlserver::database{ '#{@db_name}':
          containment => 'PARTIAL',
          db_chaining => 'ON',
          require     => Sqlserver::Sp_configure['sp_config4db']
        }
        sqlserver_tsql{'testsqlserver_tsql':
            instance => 'MSSQLSERVER',
            command => "use #{@db_name};CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
            require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts 'Validate that a table can be created in the database:'
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct db_chaing setting:"
      query = "SELECT name AS Database_Name, is_db_chaining_on
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND is_db_chaining_on = '1';"

      run_sql_query(run_sql_query_opts(query, 1))
    end

    it 'Test Case C89080: Create database with optional default_fulltext_language', tier_low: true do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user   => 'sa',
          admin_pass   => 'Pupp3t1@',
        }
        sqlserver::sp_configure{ 'sp_config4db':
          config_name   => 'contained database authentication',
          value         => 1,
          reconfigure   => true,
          instance      => 'MSSQLSERVER',
        }
        sqlserver::database{ '#{@db_name}':
          containment                 => 'PARTIAL',
          default_fulltext_language   => 'Japanese',
          require                     => Sqlserver::Sp_configure['sp_config4db']
        }
        sqlserver_tsql{'testsqlserver_tsql':
            instance => 'MSSQLSERVER',
            command => "use #{@db_name};CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
            require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts 'Validate that a table can be created in the database:'
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct default_fulltext_language_name setting:"
      query = "SELECT name AS Database_Name, default_fulltext_language_name
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND default_fulltext_language_name = 'Japanese';"

      run_sql_query(run_sql_query_opts(query, 1))
    end

    it 'Test Case C89081: Create database with optional default_language' do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user   => 'sa',
          admin_pass   => 'Pupp3t1@',
        }
        sqlserver::sp_configure{ 'sp_config4db':
          config_name   => 'contained database authentication',
          value         => 1,
          reconfigure   => true,
          instance      => 'MSSQLSERVER',
        }
        sqlserver::database{ '#{@db_name}':
          containment        => 'PARTIAL',
          default_language   => 'Traditional Chinese',
          require            => Sqlserver::Sp_configure['sp_config4db']
        }
        sqlserver_tsql{'testsqlserver_tsql':
            instance => 'MSSQLSERVER',
            command => "use #{@db_name};CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
            require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      apply_manifest(pp, catch_failures: true)

      puts 'Validate that a table can be created in the database:'
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct default_language setting:"
      query = "SELECT name AS Database_Name, default_language_name
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND default_language_lcid = '1028';"

      run_sql_query(run_sql_query_opts(query, 1))
      # rubocop:enable RSpec/InstanceVariable
    end
  end
end
