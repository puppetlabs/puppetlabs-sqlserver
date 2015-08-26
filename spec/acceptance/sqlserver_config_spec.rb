require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one("sql_host")

# Get instance name
INST_NAME = ("MSSQL" + SecureRandom.hex(4)).upcase

# Get database name
DB_NAME   = ("DB" + SecureRandom.hex(4)).upcase

describe "sqlserver::config test", :node => host do
  version = host['sql_version'].to_s

  def ensure_sqlserver_instance(host, ensure_val = 'present')
    create_new_instance= <<-MANIFEST
      sqlserver_instance{'#{INST_NAME}':
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

  context "can create sqlserver::config" do

    before(:all) do
      # Create new instance
      ensure_sqlserver_instance(host)

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
      sqlserver::config{'#{INST_NAME}':
        instance_name => '#{INST_NAME}',
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver::login{'#{@admin_user}':
        instance    => '#{INST_NAME}',
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
      sqlserver::config{'#{INST_NAME}':
        admin_user    => '#{@admin_user}',
        admin_pass    => '#{@admin_pass}',
        instance_name => '#{INST_NAME}',
      }
      sqlserver::database{'#{DB_NAME}':
        instance => '#{INST_NAME}',
      }
      MANIFEST
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end
    end

    it "Validate new login and database actualy created" do
      hostname = host.hostname
      query = "USE #{DB_NAME};"

      output = run_sql_query(host, {:query => query, :server => hostname, :instance => INST_NAME, :sql_admin_user => @admin_user, :sql_admin_pass => @admin_pass})
      expect(output).to match(/Changed database context to '#{Regexp.new(DB_NAME)}'/)
    end

    it "Validate New Config WITHOUT using instance_name in sqlserver::config" do
      pp = <<-MANIFEST
      sqlserver::config{'#{INST_NAME}':
        admin_user    => '#{@admin_user}',
        admin_pass    => '#{@admin_pass}',
      }
      sqlserver::database{'#{DB_NAME}':
        instance => '#{INST_NAME}',
      }
      MANIFEST
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end
    end

    it "Negative test: sqlserver::config without admin_user" do
      pp = <<-MANIFEST
      sqlserver::config{'#{INST_NAME}':
          admin_pass    => '#{@admin_pass}',
          instance_name => '#{INST_NAME}',
      }
      sqlserver::database{'#{DB_NAME}':
          instance => '#{INST_NAME}',
      }
      MANIFEST
      apply_manifest_on(host, pp, {:acceptable_exit_codes => [0,1]}) do |r|
        expect(r.stderr).to match(/Error: Must pass admin_user to Sqlserver/)

      end
    end

    it "Negative test: sqlserver::config without admin_pass" do
      pp = <<-MANIFEST
      sqlserver::config{'#{INST_NAME}':
          admin_user    => '#{@admin_user}',
          instance_name => '#{INST_NAME}',
      }
      sqlserver::database{'#{DB_NAME}':
          instance => '#{INST_NAME}',
      }
      MANIFEST
      apply_manifest_on(host, pp, {:acceptable_exit_codes => [0,1]}) do |r|
        expect(r.stderr).to match(/Error: Must pass admin_pass to Sqlserver/)
      end
    end
  end
end
