require 'spec_helper_acceptance'
require 'securerandom'

host = find_only_one('sql_host')
db_name     = ('DB' + SecureRandom.hex(4)).upcase
table_name  = 'Tables_' + SecureRandom.hex(3)

# Covers testrail => ['89118', '89119', '89120', '89121', '89122', '89123', '89124', '89125', '89540']
describe 'Test sqlserver::login', node: host do
  def ensure_manifest_execute(pp)
    execute_manifest(pp) do |r|
      expect(r.stderr).not_to match(%r{Error}i)
    end
  end

  # Return options for run_sql_query
  def run_sql_query_opts(user, passwd, query, expected_row_count)
    {
      query: query,
      sql_admin_user: user,
      sql_admin_pass: passwd,
      expected_row_count: expected_row_count,
    }
  end

  def run_sql_query_opts_as_sa(query, expected_row_count)
    run_sql_query_opts('sa', 'Pupp3t1@', query, expected_row_count)
  end

  def remove_test_logins(_host)
    pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::login{'#{@login_user}':
        instance  => 'MSSQLSERVER',
        ensure    => 'absent',
      }
      sqlserver::login{'#{@login_windows_user}':
        instance  => 'MSSQLSERVER',
        ensure    => 'absent',
      }
      sqlserver::login{'#{@login_windows_group}':
        instance  => 'MSSQLSERVER',
        ensure    => 'absent',
      }
    MANIFEST
    ensure_manifest_execute(pp)
  end

  def create_login_manifest(testcase, login_name, login_password, options = {})
    case testcase
    when 'SQL_LOGIN user'
      login_type = 'SQL_LOGIN'
    when 'WINDOWS_LOGIN user'
      login_type = 'WINDOWS_LOGIN'
    when 'WINDOWS_LOGIN group'
      login_type = 'WINDOWS_LOGIN'
    else
      raise "Unknown testcase name #{testcase}"
    end

    pp = <<-MANIFEST # rubocop:disable Lint/UselessAssignment
          sqlserver::config{'MSSQLSERVER':
            admin_user    => 'sa',
            admin_pass    => 'Pupp3t1@',
          }
          sqlserver::login{'#{login_name}':
            instance    => 'MSSQLSERVER',
            login_type  => '#{login_type}',
            #{"password => '#{login_password}'," if testcase == 'SQL_LOGIN user'}
            #{options['svrroles'].nil? ? "svrroles => {'sysadmin' => 1}," : "svrroles => #{options['svrroles']},"}
            #{"check_expiration => #{options['check_expiration']}," unless options['check_expiration'].nil?}
            #{"check_policy => #{options['check_policy']}," unless options['check_policy'].nil?}
            #{"default_database => '#{options['default_database']}'," unless options['default_database'].nil?}
            #{"default_language => '#{options['default_language']}'," unless options['default_language'].nil?}
            #{"disabled => #{options['disabled']}," unless options['disabled'].nil?}
            #{"ensure => '#{options['ensure']}'," unless options['ensure'].nil?}
          }
        MANIFEST
  end

  before(:all) do
    @login_user    = 'Login' + SecureRandom.hex(4)
    @login_passwd  = 'Password1!' + SecureRandom.hex(5)
    @windows_user  = 'User' + SecureRandom.hex(4)
    @windows_group = 'Group' + SecureRandom.hex(4)

    host_shortname = on(host, 'hostname').stdout.upcase.strip # Require the NETBIOS name for later database searches
    @login_windows_user  = host_shortname + '\\' + @windows_user
    @login_windows_group = host_shortname + '\\' + @windows_group

    # Create a database, a simple table and windows accounts fixtures
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

      user {'#{@windows_user}':
        password => '#{@login_passwd}',
        ensure   => 'present',
      }
      group {'#{@windows_group}':
        ensure  => 'present',
      }
    MANIFEST
    ensure_manifest_execute(pp)
  end

  # Delete all test fixtures
  after(:all) do
    remove_test_logins(host)

    pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::database{'#{db_name}':
        instance  => 'MSSQLSERVER',
        ensure    => 'absent',
      }
      user {'#{@windows_user}':
        ensure   => 'absent',
      }
      group {'#{@windows_group}':
        ensure  => 'absent',
      }
    MANIFEST
    ensure_manifest_execute(pp)
  end

  ['SQL_LOGIN user', 'WINDOWS_LOGIN user', 'WINDOWS_LOGIN group'].each do |testcase|
    context "#{testcase} tests" do
      before(:all) do
        case testcase
        when 'SQL_LOGIN user'
          @login_under_test = @login_user
          @sql_principal_type = 'S'
        when 'WINDOWS_LOGIN user'
          @login_under_test = @login_windows_user
          @sql_principal_type = 'U'
        when 'WINDOWS_LOGIN group'
          @login_under_test = @login_windows_group
          @sql_principal_type = 'G'
        else
          raise "Unknown testcase name #{testcase}"
        end
      end

      describe "Create deafult #{testcase} login" do
        before(:all) { remove_test_logins(host) }

        it "can create a default #{testcase}", tier_low: true do
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd)
          ensure_manifest_execute(pp)
        end

        it 'exists in the principals table', tier_low: true do
          query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end

        if testcase == 'SQL_LOGIN user'
          it 'can login to SQL Server', tier_low: true do
            puts "Validate the login '#{@login_under_test}' is successfully created and able to access database '#{db_name}':"
            query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}';"
            run_sql_query(host, run_sql_query_opts(@login_under_test, @login_passwd, query, 1))
          end
        end

        it 'is idempotent', tier_low: true do
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd)
          ensure_manifest_execute(pp)
        end
      end

      describe "Create #{testcase} login with 'check_expiration','check_policy'", if: testcase == 'SQL_LOGIN user' do
        # check_expiration and check_policy are only applicable to SQL based logins

        before(:all) { remove_test_logins(host) }
        it "can create an #{testcase} with 'check_expiration','check_policy' set", tier_low: true do
          options = { 'check_expiration' => true, 'check_policy' => true }
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd, options)
          ensure_manifest_execute(pp)
        end

        it 'has is_expiration_checked set', tier_low: true do
          query = "SELECT name as LOGIN_NAME, is_expiration_checked FROM SYS.SQL_LOGINS WHERE is_expiration_checked = '1' AND name = '#{@login_under_test}';"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end

        it 'has is_policy_checked set', tier_low: true do
          query = "SELECT name as LOGIN_NAME, is_policy_checked FROM SYS.SQL_LOGINS WHERE is_policy_checked = '1' AND name = '#{@login_under_test}';"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end
      end

      describe "Create #{testcase} login with 'default_database','default_language'" do
        before(:all) { remove_test_logins(host) }

        it "can create a #{testcase} with 'default_database','default_language'", tier_low: true do
          options = { 'default_database' => db_name.to_s, 'default_language' => 'Spanish' }
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd, options)
          ensure_manifest_execute(pp)
        end

        it 'exists in the principals table', tier_low: true do
          query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end

        it 'has the specified default database', tier_low: true do
          query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}' AND default_database_name = '#{db_name}'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end

        it 'has the specified default langauge', tier_low: true do
          query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}' AND default_language_name = 'Spanish'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end
      end

      describe "Create #{testcase} login with 'disabled'" do
        before(:all) { remove_test_logins(host) }

        it "can create #{testcase} with optional 'disabled'", tier_low: true do
          options = { 'disabled' => true }
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd, options)
          ensure_manifest_execute(pp)
        end

        if testcase == 'WINDOWS_LOGIN group'
          it 'has DENY CONNECT SQL set', tier_low: true do
            query = "SELECT sp.[state] FROM sys.server_principals p
                    INNER JOIN sys.server_permissions sp ON p.principal_id = sp.grantee_principal_id
                    WHERE sp.permission_name = 'CONNECT SQL' AND sp.class = 100 AND sp.state = 'D' AND p.name = '#{@login_under_test}' AND p.[type] = '#{@sql_principal_type}'"
            run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
          end
        else
          it 'has is_disabled set' do
            query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}' AND is_disabled = '1';"
            run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
          end
        end
      end

      describe "Modify a #{testcase} login" do
        before(:all) { remove_test_logins(host) }

        it "should create an initial #{testcase}", tier_low: true do
          options = { 'svrroles' => '{\'sysadmin\' => 1}' }
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd, options)
          ensure_manifest_execute(pp)
        end

        it 'exists in the principals table on creation', tier_low: true do
          query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end

        it "should modify a #{testcase} login", tier_low: true do
          options = { 'disabled' => true,
                      'default_database' => db_name.to_s,
                      'default_language' => 'Spanish',
                      'check_expiration' => true,
                      'check_policy' => true,
                      'svrroles' => '{\'sysadmin\' => 1, \'serveradmin\' => 1}' }
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd, options)
          ensure_manifest_execute(pp)
        end

        if testcase == 'SQL_LOGIN user'
          it 'has is_expiration_checked set', tier_low: true do
            query = "SELECT name as LOGIN_NAME, is_expiration_checked FROM SYS.SQL_LOGINS WHERE is_expiration_checked = '1' AND name = '#{@login_under_test}';"
            run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
          end

          it 'has is_policy_checked set', tier_low: true do
            query = "SELECT name as LOGIN_NAME, is_policy_checked FROM SYS.SQL_LOGINS WHERE is_policy_checked = '1' AND name = '#{@login_under_test}';"
            run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
          end
        end

        it 'has the specified sysadmin role', tier_low: true do
          # Note - IS_SRVROLEMEMBER always returns false for a disabled WINDOWS_LOGIN user login
          query = "SELECT pri.name from sys.server_role_members member
                    JOIN sys.server_principals rol ON member.role_principal_id = rol.principal_id
                    JOIN sys.server_principals pri ON member.member_principal_id = pri.principal_id
                    WHERE rol.type_desc = 'SERVER_ROLE'
                    AND rol.name = 'sysadmin'
                    AND pri.name = '#{@login_under_test}'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end
        it 'has the specified serveradmin role', tier_low: true do
          # Note - IS_SRVROLEMEMBER always returns false for a disabled WINDOWS_LOGIN user login
          query = "SELECT pri.name from sys.server_role_members member
                    JOIN sys.server_principals rol ON member.role_principal_id = rol.principal_id
                    JOIN sys.server_principals pri ON member.member_principal_id = pri.principal_id
                    WHERE rol.type_desc = 'SERVER_ROLE'
                    AND rol.name = 'serveradmin'
                    AND pri.name = '#{@login_under_test}'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end

        it 'has the specified default database', tier_low: true do
          query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}' AND default_database_name = '#{db_name}'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end

        it 'has the specified default langauge', tier_low: true do
          query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}' AND default_language_name = 'Spanish'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end

        if testcase == 'WINDOWS_LOGIN group'
          it 'has DENY CONNECT SQL set', tier_low: true do
            query = "SELECT sp.[state] FROM sys.server_principals p
                    INNER JOIN sys.server_permissions sp ON p.principal_id = sp.grantee_principal_id
                    WHERE sp.permission_name = 'CONNECT SQL' AND sp.class = 100 AND sp.state = 'D' AND p.name = '#{@login_under_test}' AND p.[type] = '#{@sql_principal_type}'"
            run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
          end
        else
          it 'has is_disabled set', tier_low: true do
            query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}' AND is_disabled = '1';"
            run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
          end
        end
      end

      describe "Delete #{testcase} login" do
        before(:all) { remove_test_logins(host) }

        it "should create an initial #{testcase}", tier_low: true do
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd)
          ensure_manifest_execute(pp)
        end

        it 'exists in the principals table on creation', tier_low: true do
          query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 1))
        end

        it "should remove a #{testcase} on ensure => absent", tier_low: true do
          options = { 'ensure' => 'absent' }
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd, options)
          ensure_manifest_execute(pp)
        end

        it "remove a #{testcase} should be idempotent", tier_low: true do
          options = { 'ensure' => 'absent' }
          pp = create_login_manifest(testcase, @login_under_test, @login_passwd, options)
          execute_manifest(pp, catch_changes: true)
        end

        it 'does not exist in the principals table after deletion', tier_low: true do
          query = "SELECT principal_id FROM SYS.server_principals WHERE name = '#{@login_under_test}' AND [type] = '#{@sql_principal_type}'"
          run_sql_query(host, run_sql_query_opts_as_sa(query, 0))
        end
        # rubocop:enable RSpec/InstanceVariable
      end
    end
  end
end
