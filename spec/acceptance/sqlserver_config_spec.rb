# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

# Get instance name
inst_name = "MSSQL#{SecureRandom.hex(4)}".upcase
# Get database name
db_name   = "DB#{SecureRandom.hex(4)}".upcase

describe 'sqlserver::config test' do
  def ensure_sqlserver_instance(inst_name, ensure_val = 'present')
    user = Helper.instance.run_shell('$env:UserName').stdout.chomp
    pp = <<-MANIFEST
      sqlserver_instance{'#{inst_name}':
      ensure                => '#{ensure_val}',
      source                => 'H:',
      features              => ['DQ', 'FullText', 'Replication', 'SQLEngine'],
      sql_sysadmin_accounts => ['#{user}'],
      security_mode         => 'SQL',
      sa_pwd                => 'Pupp3t1@',
      windows_feature_source => 'I:\\sources\\sxs',
      install_switches => {
        'UpdateEnabled'         => 'false',
        'SkipInstallerRunCheck' => 'True',
      },
    }
    MANIFEST
    retry_on_error_matching(10, 5, %r{apply manifest failed}) do
      apply_manifest(pp, catch_failures: true)
    end
  end

  context 'Testing sqlserver::config' do
    before(:all) do
      # Create new instance
      ensure_sqlserver_instance(inst_name)

      # get credentials for new config
      @admin_user = "test_user#{SecureRandom.hex(2)}"
      @admin_pass = 'Pupp3t1@'

      # get database user
      @db_user    = "dbuser#{SecureRandom.hex(2)}"
    end

    after(:all) do
      # remove the newly created instance
      ensure_sqlserver_instance(inst_name, 'absent')
    end

    it 'Create New Admin Login:' do
      pp = <<-MANIFEST
      sqlserver::config{'#{inst_name}':
        instance_name => '#{inst_name}',
        admin_user    => Sensitive('sa'),
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
      apply_manifest(pp, catch_failures: true)
    end

    it 'Validate New Config WITH instance_name in sqlserver::config' do
      pp = <<-MANIFEST
      sqlserver::config{'#{inst_name}':
        admin_user    => Sensitive('#{@admin_user}'),
        admin_pass    => Sensitive('#{@admin_pass}'),
        instance_name => '#{inst_name}',
      }
      sqlserver::database{'#{db_name}':
        instance => '#{inst_name}',
      }
      MANIFEST
      apply_manifest(pp, catch_failures: true)
    end

    it 'Validate new login and database actualy created' do
      hostname = Helper.instance.run_shell('hostname').stdout.upcase.strip
      query = "USE #{db_name}; SELECT * from master..sysdatabases WHERE name = '#{db_name}'"

      run_sql_query(query: query, server: hostname, instance: inst_name, \
                    sql_admin_user: @admin_user, sql_admin_pass: @admin_pass, expected_row_count: 1)
    end

    it 'Validate New Config WITHOUT using instance_name in sqlserver::config' do
      pp = <<-MANIFEST
      sqlserver::config{'#{inst_name}':
        admin_user    => '#{@admin_user}',
        admin_pass    => '#{@admin_pass}',
      }
      sqlserver::database{'#{db_name}':
        instance => '#{inst_name}',
      }
      MANIFEST
      apply_manifest(pp, catch_failures: true)
    end
  end
end
