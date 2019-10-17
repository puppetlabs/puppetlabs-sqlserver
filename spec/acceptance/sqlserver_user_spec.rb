require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one('sql_host')
hostname = host.hostname

# database name
db_name = ('DB' + SecureRandom.hex(4)).upcase

describe 'sqlserver::user test', node: host do
  def ensure_sqlserver_database(db_name, _ensure_val = 'present')
    pp = <<-MANIFEST
    sqlserver::config{'MSSQLSERVER':
      admin_user   => 'sa',
      admin_pass   => 'Pupp3t1@',
    }
    sqlserver::sp_configure{ 'spconfig1':
      config_name   => 'contained database authentication',
      value         => 1,
      reconfigure   => true,
      instance      => 'MSSQLSERVER',
    }
    sqlserver::database{ '#{db_name}':
      instance            => 'MSSQLSERVER',
      collation_name      => 'SQL_Estonian_CP1257_CS_AS',
      compatibility       => 100,
      containment         => 'PARTIAL',
      require             => Sqlserver::Sp_configure['spconfig1']
    }
    MANIFEST

    execute_manifest(pp) do |r|
      expect(r.stderr).not_to match(%r{Error}i)
    end
  end

  context 'Create database users with optional attributes', testrail: ['89143', '89144', '89145', '89146', '89149'] do
    before(:all) do
      # Create new database
      ensure_sqlserver_database(db_name)
    end
    before(:each) do
      @new_sql_login = 'Login' + SecureRandom.hex(2)
      @db_user = 'DBuser' + SecureRandom.hex(2)
    end

    after(:all) do
      # remove the newly created database
      # Temporarily skip delete database because of MODULES-2554
      # ensure_sqlserver_database(host, 'absent')
    end

    it 'Create database user with optional default_schema', tier_low: true do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::login{'#{@db_user}':
        instance    => 'MSSQLSERVER',
        login_type  => 'SQL_LOGIN',
        password    => 'Pupp3t1@',
      }
      sqlserver::user{'#{@db_user}':
        database        => '#{db_name}',
        user            => '#{@db_user}',
        default_schema  => 'guest',
        require         => Sqlserver::Login['#{@db_user}'],
      }
      MANIFEST
      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end

      # validate that the database user '#{@db_user}' is successfully created with default schema 'guest':
      query = "USE #{db_name};
              SELECT name AS Database_User_Name, default_schema_name
              FROM SYS.DATABASE_PRINCIPALS
              WHERE name = '#{@db_user}'
              AND
              default_schema_name = 'guest';"
      run_sql_query(host, query: query, server: hostname, expected_row_count: 1)
    end

    it 'Create database user with optional instance', tier_low: true do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::login{'#{@db_user}':
        instance    => 'MSSQLSERVER',
        login_type  => 'SQL_LOGIN',
        password    => 'Pupp3t1@',
      }
      sqlserver::user{'#{@db_user}':
        instance        => 'MSSQLSERVER',
        database        => '#{db_name}',
        user            => '#{@db_user}',
        require         => Sqlserver::Login['#{@db_user}'],
      }
        MANIFEST
      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end

      # validate that the database user '#{@db_user}' is successfully created:
      query = "USE #{db_name};
              SELECT name AS Database_User_Name
              FROM SYS.DATABASE_PRINCIPALS
              WHERE name = '#{@db_user}';"
      run_sql_query(host, query: query, server: hostname, expected_row_count: 1)
    end

    it 'Create database user with optional login', tier_low: true do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::login{'#{@new_sql_login}':
        instance    => 'MSSQLSERVER',
        login_type  => 'SQL_LOGIN',
        password    => 'Pupp3t1@',
      }
      sqlserver::user{'#{@db_user}':
        instance        => 'MSSQLSERVER',
        database        => '#{db_name}',
        login           => '#{@new_sql_login}',
        user            => '#{@db_user}',
        require         => Sqlserver::Login['#{@new_sql_login}'],
      }
      MANIFEST
      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end

      # validate that the database user '#{@db_user}' is mapped with sql login '#{@new_sql_login}':
      query = "USE #{db_name};
              SELECT d.name AS Database_User, l.name as Associated_sql_login
              FROM SYS.DATABASE_PRINCIPALS d, MASTER.SYS.SQL_LOGINS l
              WHERE d.sid = l.sid
              AND d.name = '#{@db_user}';"
      run_sql_query(host, query: query, server: hostname, expected_row_count: 1)
    end

    it 'Create database user with optional password', tier_low: true do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::login{'#{@new_sql_login}':
        instance    => 'MSSQLSERVER',
        login_type  => 'SQL_LOGIN',
        password    => 'Pupp3t1@',
      }
      sqlserver::user{'#{@db_user}':
        instance        => 'MSSQLSERVER',
        database        => '#{db_name}',
        login           => '#{@new_sql_login}',
        user            => '#{@db_user}',
        password        => 'databaseUserPasswd',
        require         => Sqlserver::Login['#{@new_sql_login}'],
      }
      MANIFEST
      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end

      puts "validate that the database user '#{@db_user}' is successfully created:"
      query = "USE #{db_name}; SELECT * FROM SYS.DATABASE_PRINCIPALS WHERE name = '#{@db_user}';"
      run_sql_query(host, query: query, server: hostname, expected_row_count: 1)
    end

    it 'Delete database user', tier_low: true do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::login{'#{@db_user}':
        instance    => 'MSSQLSERVER',
        login_type  => 'SQL_LOGIN',
        password    => 'Pupp3t1@',
      }
      sqlserver::user{'#{@db_user}':
        database        => '#{db_name}',
        require         => Sqlserver::Login['#{@db_user}'],
      }
      MANIFEST
      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end

      # validate that the database user '#{@db_user}' is successfully created:
      query = "USE #{db_name}; SELECT * FROM SYS.DATABASE_PRINCIPALS WHERE name = '#{@db_user}';"
      run_sql_query(host, query: query, server: hostname, expected_row_count: 1)

      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::user{'#{@db_user}':
        ensure          => 'absent',
        database        => '#{db_name}',
      }
      MANIFEST
      execute_manifest(pp) do |r|
        expect(r.stderr).not_to match(%r{Error}i)
      end
      # validate that the database user '#{@db_user}' should be deleted:
      query = "USE #{db_name}; SELECT * FROM SYS.DATABASE_PRINCIPALS WHERE name = '#{@db_user}';"
      run_sql_query(host, query: query, server: hostname, expected_row_count: 0)
    end
  end
end
