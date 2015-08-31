require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one("sql_host")

# database name
DB_NAME   = ("DB" + SecureRandom.hex(4)).upcase

#database user:
DB_LOGIN_USER   = "loginuser" + SecureRandom.hex(2)

describe "sqlserver_database test", :node => host do

  def ensure_sqlserver_database(host, ensure_val = 'present')
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

    sqlserver::database{ '#{DB_NAME}':
      instance            => 'MSSQLSERVER',
      collation_name      => 'SQL_Estonian_CP1257_CS_AS',
      compatibility       => '100',
      containment         => 'PARTIAL',
      require             => Sqlserver::Sp_configure['spconfig1']
    }
    MANIFEST

    apply_manifest_on(host, pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  context "server_url =>", {:testrail => ['89078']} do

    before(:all) do
      # Create new database
      @table_name = 'Tables_' + SecureRandom.hex(3)
      @query = "USE #{DB_NAME}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"

      ensure_sqlserver_database(host)
    end

    after(:all) do
      # remove the newly created instance
      ensure_sqlserver_database(host, 'absent')
    end

    it "Run a simple tsql command via sqlserver_tsql:" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          instance_name => 'MSSQLSERVER',
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{DB_NAME}',
          command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
        }
      MANIFEST
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      puts "validate the result of tsql command and table #{@table_name} should be created:"
      run_sql_query(host, {:query => @query, :sql_admin_user => @admin_user, \
          :sql_admin_pass => @admin_pass, :expected_row_count => 1})
    end
  end
end
