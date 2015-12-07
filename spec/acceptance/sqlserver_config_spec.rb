require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one("sql_host")

# Get instance name
inst_name = ("MSSQL" + SecureRandom.hex(4)).upcase

# Get database name
db_name   = ("DB" + SecureRandom.hex(4)).upcase

describe "sqlserver::config test", :node => host do

  def ensure_sqlserver_instance(host,inst_name, ensure_val = 'present')
    create_new_instance= <<-MANIFEST
      sqlserver_instance{'#{inst_name}':
      ensure                => '#{ensure_val}',
      source                => 'H:',
      features              => [ 'SQL' ],
      sql_sysadmin_accounts => ['Administrator'],
      security_mode         => 'SQL',
      sa_pwd                => 'Pupp3t1@',
    }
    MANIFEST

    apply_manifest_on(host, create_new_instance) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  context "Testing sqlserver::config", {:testrail => ['89070', '89071', '89072', '89073']} do

    before(:all) do
      # Create new instance
      ensure_sqlserver_instance(host, inst_name)

      # get credentials for new config
      @admin_user = "admin" + SecureRandom.hex(2)
      @admin_pass = 'Pupp3t1@'

      # get database user
      @db_user    = "dbuser" + SecureRandom.hex(2)
    end

    after(:all) do
      # remove the newly created instance
      ensure_sqlserver_instance(host, 'absent')
    end

    it "Create New Admin Login:" do
      create_new_login = <<-MANIFEST
      sqlserver::config{'#{inst_name}':
        instance_name => '#{inst_name}',
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::login{'#{@admin_user}':
        instance    => '#{inst_name}',
        login_type  => 'SQL_LOGIN',
        login       => '#{@admin_user}',
        password    => '#{@admin_pass}',
        svrroles    => {'sysadmin' => 1},
      }
      MANIFEST
      apply_manifest_on(host, create_new_login) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end
    end

    it "Validate New Config WITH using instance_name in sqlserver::config" do
      pp = <<-MANIFEST
      sqlserver::config{'#{inst_name}':
        admin_user    => '#{@admin_user}',
        admin_pass    => '#{@admin_pass}',
        instance_name => '#{inst_name}',
      }
      sqlserver::database{'#{db_name}':
        instance => '#{inst_name}',
      }
      MANIFEST
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end
    end

    it "Validate new login and database actualy created" do
      hostname = host.hostname
      query = "USE #{db_name}; SELECT * from master..sysdatabases WHERE name = '#{db_name}'"

      run_sql_query(host, {:query => query, :server => hostname, :instance => inst_name, \
      :sql_admin_user => @admin_user, :sql_admin_pass => @admin_pass, :expected_row_count => 1})
    end

    it "Validate New Config WITHOUT using instance_name in sqlserver::config" do
      pp = <<-MANIFEST
      sqlserver::config{'#{inst_name}':
        admin_user    => '#{@admin_user}',
        admin_pass    => '#{@admin_pass}',
      }
      sqlserver::database{'#{db_name}':
        instance => '#{inst_name}',
      }
      MANIFEST
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end
    end
  end
end
