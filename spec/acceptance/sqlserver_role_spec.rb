require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one("sql_host")
hostname = host.hostname

# database name
db_name   = ("DB" + SecureRandom.hex(4)).upcase
LOGIN1    = "Login1_" + SecureRandom.hex(2)
LOGIN2    = "Login2_" + SecureRandom.hex(2)
LOGIN3    = "Login3_" + SecureRandom.hex(2)
USER1     = "User1_" + SecureRandom.hex(2)

describe "Test sqlserver::role", :node => host do

  def ensure_sqlserver_logins_users(db_name)
    pp = <<-MANIFEST
    sqlserver::config{'MSSQLSERVER':
      admin_user   => 'sa',
      admin_pass   => 'Pupp3t1@',
    }
    sqlserver::database{ '#{db_name}':
    }
    sqlserver::login{'#{LOGIN1}':
      login_type  => 'SQL_LOGIN',
      password    => 'Pupp3t1@',
    }
    sqlserver::login{'#{LOGIN2}':
      login_type  => 'SQL_LOGIN',
      password    => 'Pupp3t1@',
    }
    sqlserver::login{'#{LOGIN3}':
      login_type  => 'SQL_LOGIN',
      password    => 'Pupp3t1@',
    }
    sqlserver::user{'#{USER1}':
      database        => '#{db_name}',
      user            => '#{USER1}',
      login           => '#{LOGIN1}',
      default_schema  => 'guest',
      require         => Sqlserver::Login['#{LOGIN1}'],
    }
    MANIFEST
    execute_manifest(pp, opts = {}) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  context "Start testing sqlserver::role", {:testrail => ['89161', '89162', '89163', '89164', '89165']} do
    before(:all) do
      # Create database users
      ensure_sqlserver_logins_users(db_name)
    end
    before(:each) do
      @role = "Role_" + SecureRandom.hex(2)
    end
    after(:each) do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::role{'#{@role}':
        ensure  => 'absent',
      }
      MANIFEST
      execute_manifest(pp, opts = {}) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end
    end

    after(:all) do
      # remove all newly created logins
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::user{'#{USER1}':
        database  => '#{db_name}',
        ensure    => 'absent',
      }
      MANIFEST
      execute_manifest(pp, opts = {}) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end
    end

    it "Create server role #{@role} with optional authorization", :tier_low => true do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::role{'ServerRole':
        ensure        => 'present',
        authorization => '#{LOGIN1}',
        role          => '#{@role}',
        permissions   => {'GRANT' => ['CREATE ENDPOINT', 'CREATE ANY DATABASE']},
        type          => 'SERVER',
      }
      MANIFEST
      execute_manifest(pp, opts = {}) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      #validate that the database-specific role '#{@role}' is successfully created with specified permissions':
      query = "USE #{db_name};
      SELECT spr.principal_id, spr.name,
              spe.state_desc, spe.permission_name
      FROM sys.server_principals AS spr
      JOIN sys.server_permissions AS spe
      ON spe.grantee_principal_id = spr.principal_id
      WHERE spr.name = '#{@role}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 2 })

      # validate that the database-specific role '#{@role}' has correct authorization #{LOGIN1}
      query = "USE #{db_name};
      SELECT spr.name, sl.name
      FROM sys.server_principals AS spr
      JOIN sys.sql_logins AS sl
        ON spr.owning_principal_id = sl.principal_id
      WHERE sl.name = '#{LOGIN1}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 1 })
    end

    it "Create database-specific role #{@role}", :tier_low => true do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::role{'DatabaseRole':
        ensure      => 'present',
        role        => '#{@role}',
        database    => '#{db_name}',
        permissions => {'GRANT' => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CONTROL', 'ALTER']},
        type        => 'DATABASE',
      }
      MANIFEST
      execute_manifest(pp, opts = {}) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      # validate that the database-specific role '#{@role}' is successfully created with specified permissions':
      query = "USE #{db_name};
      SELECT pr.principal_id, pr.name, pr.type_desc,
              pr.authentication_type_desc, pe.state_desc, pe.permission_name
      FROM sys.database_principals AS pr
      JOIN sys.database_permissions AS pe
        ON pe.grantee_principal_id = pr.principal_id
      WHERE pr.name = '#{@role}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 6 })
    end

    it "Create server role #{@role} with optional members and optional members-purge", :tier_low => true do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::role{'ServerRole':
        instance    => 'MSSQLSERVER',
        ensure      => 'present',
        role        => '#{@role}',
        permissions => {'GRANT' => ['CREATE ENDPOINT', 'CREATE ANY DATABASE']},
        type        => 'SERVER',
        members     => ['#{LOGIN1}', '#{LOGIN2}', '#{LOGIN3}'],
      }
      MANIFEST
      execute_manifest(pp, opts = {}) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      #validate that the server role '#{@role}' is successfully created with specified permissions':
      query = "USE #{db_name};
      SELECT spr.principal_id AS ID, spr.name AS Server_Role,
              spe.state_desc, spe.permission_name
      FROM sys.server_principals AS spr
      JOIN sys.server_permissions AS spe
        ON spe.grantee_principal_id = spr.principal_id
      WHERE spr.name = '#{@role}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 2 })

      #validate that the t server role '#{@role}' has correct members (Login1, 2, 3)
      query = "USE #{db_name};
      SELECT spr.principal_id AS ID, spr.name AS ServerRole
      FROM sys.server_principals AS spr
      JOIN sys.server_role_members m
        ON spr.principal_id = m.member_principal_id
      WHERE spr.name = '#{LOGIN1}'
        OR spr.name = '#{LOGIN2}'
        OR spr.name = '#{LOGIN3}'
        OR spr.name = 'LOGIN4';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 3 })

      puts "Create server role #{@role} with optional members_purge:"
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::role{'ServerRole':
        instance    => 'MSSQLSERVER',
        ensure      => 'present',
        role        => '#{@role}',
        permissions => {'GRANT' => ['CREATE ENDPOINT', 'CREATE ANY DATABASE']},
        type        => 'SERVER',
        members     => ['#{LOGIN3}'],
        members_purge => true,
      }
      MANIFEST
      execute_manifest(pp, opts = {}) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      #validate that the t server role '#{@role}' has correct members (only Login3)
      query = "USE #{db_name};
      SELECT spr.principal_id AS ID, spr.name AS ServerRole
      FROM sys.server_principals AS spr
      JOIN sys.server_role_members m
        ON spr.principal_id = m.member_principal_id
      WHERE spr.name = '#{LOGIN1}'
        OR spr.name = '#{LOGIN2}'
        OR spr.name = '#{LOGIN3}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 1 })
    end
  end
end
