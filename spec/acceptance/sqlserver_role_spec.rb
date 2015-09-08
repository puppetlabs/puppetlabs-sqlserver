require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one("sql_host")
hostname = host.hostname

# database name
DB_NAME   = ("DB" + SecureRandom.hex(4)).upcase
LOGIN1    = "Login1_" + SecureRandom.hex(2)
LOGIN2    = "Login2_" + SecureRandom.hex(2)
LOGIN3    = "Login3_" + SecureRandom.hex(2)
USER1     = "User1_" + SecureRandom.hex(2)

describe "Test sqlserver::role", :node => host do


  def ensure_sqlserver_logins_users(host)
    pp = <<-MANIFEST
    sqlserver::config{'MSSQLSERVER':
      admin_user   => 'sa',
      admin_pass   => 'Pupp3t1@',
    }
    sqlserver::database{ '#{DB_NAME}':
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
      database        => '#{DB_NAME}',
      user            => '#{USER1}',
      login           => '#{LOGIN1}',
      default_schema  => 'guest',
      require         => Sqlserver::Login['#{LOGIN1}'],
    }
    MANIFEST
    apply_manifest_on(host, pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  context "Test sqlser::role", {:testrail => ['89161', '89162', '89163', '89164', '89165']} do
    before(:all) do
      # Create database users
      ensure_sqlserver_logins_users(host)
    end
    before(:each) do
      #@new_sql_login = "Login" + SecureRandom.hex(2)
      @role = "Role_" + SecureRandom.hex(2)
    end

    after(:all) do
      # remove the newly created database
      pp = <<-MANIFEST
      sqlserver::database{ '#{DB_NAME}':
      ensure => 'absent',
      }
      MANIFEST
      # apply_manifest_on(host, pp) do |r|
      #   expect(r.stderr).not_to match(/Error/i)
      # end
    end

    it "Create server role #{@role} with optional authorization" do
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
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      #validate that the database-specific role '#{@role}' is successfully created with specified permissions':
      query = "USE #{DB_NAME};
      SELECT spr.principal_id, spr.name,
              spe.state_desc, spe.permission_name
      FROM sys.server_principals AS spr
      JOIN sys.server_permissions AS spe
      ON spe.grantee_principal_id = spr.principal_id
      WHERE spr.name = '#{@role}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 2 })

      # validate that the database-specific role '#{@role}' has correct authorization #{LOGIN1}
      query = "USE #{DB_NAME};
      SELECT spr.name, sl.name
      FROM sys.server_principals AS spr
      JOIN sys.sql_logins AS sl
        ON spr.owning_principal_id = sl.principal_id
      WHERE sl.name = '#{LOGIN1}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 1 })
    end

    it "Create database-specific role: #{@role}" do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::role{'DatabaseRole':
        ensure      => 'present',
        role        => '#{@role}',
        database    => '#{DB_NAME}',
        permissions => {'GRANT' => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CONTROL', 'ALTER']},
        type        => 'DATABASE',
      }
      MANIFEST
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      # validate that the database-specific role '#{@role}' is successfully created with specified permissions':
      query = "USE #{DB_NAME};
      SELECT pr.principal_id, pr.name, pr.type_desc,
              pr.authentication_type_desc, pe.state_desc, pe.permission_name
      FROM sys.database_principals AS pr
      JOIN sys.database_permissions AS pe
        ON pe.grantee_principal_id = pr.principal_id
      WHERE pr.name = '#{@role}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 6 })
    end

    it "Create server role #{@role} with optional members" do
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
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      #validate that the server role '#{@role}' is successfully created with specified permissions':
      query = "USE #{DB_NAME};
      SELECT spr.principal_id, spr.name,
              spe.state_desc, spe.permission_name
      FROM sys.server_principals AS spr
      JOIN sys.server_permissions AS spe
        ON spe.grantee_principal_id = spr.principal_id
      WHERE spr.name = '#{@role}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 2 })

      #validate that the t server role '#{@role}' has correct members (Login1, 2, 3)
      query = "USE #{DB_NAME};
      SELECT sp1.principal_id AS LOGIN, sp1.name AS ServerRole
      FROM sys.server_principals sp1
      JOIN sys.server_role_members m
        ON sp1.principal_id = m.member_principal_id
      JOIN sys.server_principals sp2
        ON m.role_principal_id = sp2.principal_id
      WHERE sp1.name = '#{LOGIN1}'
        OR sp1.name = '#{LOGIN2}'
        OR sp1.name = '#{LOGIN3}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 3 })
    end

    it "Create server role #{@role} with optional members_purge" do
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
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      #validate that the server role '#{@role}' is successfully created with specified permissions':
      query = "USE #{DB_NAME};
      SELECT spr.principal_id, spr.name,
              spe.state_desc, spe.permission_name
      FROM sys.server_principals AS spr
      JOIN sys.server_permissions AS spe
        ON spe.grantee_principal_id = spr.principal_id
      WHERE spr.name = '#{@role}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 2 })

      #validate that the t server role '#{@role}' has correct members (Login3)
      query = "USE #{DB_NAME};
      SELECT sp1.principal_id AS ID, sp1.name AS Logins
      FROM sys.server_principals sp1
      JOIN sys.server_role_members m
        ON sp1.principal_id = m.member_principal_id
      where sp1.name = '#{@role}';"

      run_sql_query(host, { :query => query, :server => hostname, :expected_row_count => 1 })
    end
  end
end