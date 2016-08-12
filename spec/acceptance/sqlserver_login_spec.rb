require 'spec_helper_acceptance'
require 'securerandom'

host = find_only_one("sql_host")
db_name     = ("DB" + SecureRandom.hex(4)).upcase
table_name  = 'Tables_' + SecureRandom.hex(3)

describe "Test sqlserver::login", :node => host do

  def ensure_manifest_apply(host, pp)
    apply_manifest_on(host, pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  #Return options for run_sql_query
  def run_sql_query_opts (user, passwd, query, expected_row_count)
    run_sql_query_opt = {
        :query => query,
        :sql_admin_user => user,
        :sql_admin_pass => passwd,
        :expected_row_count => expected_row_count,
    }
  end

  context "Start testing...", {:testrail => ['89118', '89119', '89120', '89121', '89122', '89123', '89124', '89125', '89540']} do

    before(:all) do
      # Create a database and a simple table to use for all the tests
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{db_name}':
        }
        sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{db_name}',
          command => "CREATE TABLE #{table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          require => Sqlserver::Database['#{db_name}'],
        }
      MANIFEST
      ensure_manifest_apply(host, pp)
    end

    # Delete Database after all tests are done
    after(:all) do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{db_name}':
          instance  => 'MSSQLSERVER',
          ensure    => 'absent',
        }
      MANIFEST
      #comment out the below line because of ticket MODULES-2554(delete database)
      #ensure_manifest_apply(host, pp)
    end

    # Generate different set of sqlserver login/password for each test
    before(:each) do
      @login_user   = "Login" + SecureRandom.hex(4)
      @login_passwd = "Password" + SecureRandom.hex(5)
    end

    after(:each) do
      # delete recently created login after each test:
      # This test also cover test case C89540: Delete login
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::login{'#{@login_user}':
          instance  => 'MSSQLSERVER',
          ensure    => 'absent',
        }
      MANIFEST
      ensure_manifest_apply(host, pp)
    end

    it "Test Case C89118: create login with optional 'check_expiration'" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::login{'#{@login_user}':
          instance    => 'MSSQLSERVER',
          login_type  => 'SQL_LOGIN',
          password    => '#{@login_passwd}',
          svrroles    => {'sysadmin' => 1},
          check_expiration  => true,
        }

      MANIFEST
      ensure_manifest_apply(host, pp)

      puts "Validate the login '#{@login_user}' is successfully created and able to access database '#{db_name}':"
      query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))

      puts "Validate the login '#{@login_user}' is successfully created and has correct is_expiration_checked:"
      query = "SELECT name as LOGIN_NAME, is_expiration_checked
              FROM SYS.SQL_LOGINS
              WHERE is_expiration_checked = '1'
              AND name = '#{@login_user}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))
    end

    it "Test Case C89119: create login with optional 'check_policy'" do
      #This test also cover test case C89123: create login with optional 'instance'
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::login{'#{@login_user}':
          instance    => 'MSSQLSERVER',
          login_type  => 'SQL_LOGIN',
          password    => '#{@login_passwd}',
          svrroles    => {'sysadmin' => 1},
          check_policy  => true,
        }

      MANIFEST
      ensure_manifest_apply(host, pp)

      puts "Validate the login '#{@login_user}' is successfully created and able to access database '#{db_name}':"
      query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))

      puts "Validate the login '#{@login_user}' is successfully created and has correct is_expiration_checked:"
      query = "SELECT name as LOGIN_NAME, is_policy_checked
              FROM SYS.SQL_LOGINS
              WHERE is_policy_checked = '1'
              AND name = '#{@login_user}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))
    end

    it "Test Case C89120: create login with optional 'default_database'" do
      #This test also cover test case C89124: create login with optional 'login_type'
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::login{'#{@login_user}':
          instance    => 'MSSQLSERVER',
          login_type  => 'SQL_LOGIN',
          password    => '#{@login_passwd}',
          svrroles    => {'sysadmin' => 1},
          default_database  => '#{db_name}',
        }

      MANIFEST
      ensure_manifest_apply(host, pp)

      puts "Validate the login '#{@login_user}' is successfully created and able to access database '#{db_name}':"
      query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))

      puts "Validate the login '#{@login_user}' is successfully created and has correct default_database:"
      query = "SELECT name as LOGIN_NAME, default_database_name
              FROM SYS.SQL_LOGINS
              WHERE default_database_name = '#{db_name}'
              AND name = '#{@login_user}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))
    end

    it "Test Case C89121: create login with optional 'default_language'" do
      #This test also cover test case C89125: create login with optional 'svrroles'
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::login{'#{@login_user}':
          instance    => 'MSSQLSERVER',
          login_type  => 'SQL_LOGIN',
          password    => '#{@login_passwd}',
          svrroles    => {'sysadmin' => 1},
          default_language  => 'Spanish',
        }
      MANIFEST
      ensure_manifest_apply(host, pp)

      puts "Validate the login '#{@login_user}' is successfully created and able to access database '#{db_name}':"
      query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))

      puts "Validate the login '#{@login_user}' is successfully created and has correct default_language_name:"
      query = "SELECT name as LOGIN_NAME, default_language_name
              FROM SYS.SQL_LOGINS
              WHERE default_language_name = 'Spanish'
              AND name = '#{@login_user}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))
    end

    #Temporarily skip this test because of ticket MODULES-2305
    xit "Test Case C89122: create login with optional 'disabled'" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::login{'#{@login_user}':
          instance    => 'MSSQLSERVER',
          login_type  => 'SQL_LOGIN',
          password    => '#{@login_passwd}',
          svrroles    => {'sysadmin' => 1},
          disabled    => true,
        }
      MANIFEST
      ensure_manifest_apply(host, pp)

      puts "Validate the login '#{@login_user}' is successfully created and able to access database '#{db_name}':"
      query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))

      puts "Validate the login '#{@login_user}' is successfully created and has correct is_disabled:"
      query = "SELECT name as LOGIN_NAME, is_policy_checked
              FROM SYS.SQL_LOGINS
              WHERE is_disabled = '1'
              AND name = '#{@login_user}';"
      run_sql_query(host, run_sql_query_opts(@login_user, @login_passwd, query, expected_row_count = 1))
    end
  end
end
