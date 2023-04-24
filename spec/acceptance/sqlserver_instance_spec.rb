# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

def new_random_instance_name
  ('MSSQL' + SecureRandom.hex(4)).upcase.to_s
end

describe 'sqlserver_instance' do
  version = sql_version?

  def ensure_sqlserver_instance(features, inst_name, ensure_val = 'present', sysadmin_accounts = [])
    user = Helper.instance.run_shell('$env:UserName').stdout.chomp
    sysadmin_accounts << user
    # If no password env variable set (by CI), then default to vagrant
    password = Helper.instance.run_shell('$env:pass').stdout.chomp
    password = password.empty? ? 'vagrant' : password

    pp = <<-MANIFEST
    sqlserver_instance{'#{inst_name}':
      name                  => '#{inst_name}',
      ensure                => #{ensure_val},
      source                => 'H:',
      security_mode         => 'SQL',
      sa_pwd                => 'Pupp3t1@',
      features              => #{features},
      sql_sysadmin_accounts => #{sysadmin_accounts},
      agt_svc_account       => '#{user}',
      agt_svc_password      => '#{password}',
      windows_feature_source => 'I:\\sources\\sxs',
    }
    MANIFEST
    idempotent_apply(pp)
  end

  # Return options for run_sql_query
  def run_sql_query_opts(inst_name, query, expected_row_count)
    {
      query: query,
      instance: inst_name,
      server: '.',
      sql_admin_user: 'sa',
      sql_admin_pass: 'Pupp3t1@',
      expected_row_count: expected_row_count,
    }
  end

  def sql_query_is_user_sysadmin(username)
    <<-QUERY
    Select [Name]
      FROM SYS.Server_Principals
      WHERE (type = 'S' or type = 'U')
      AND [Name] like '%\\#{username}'
      AND is_disabled = 0 AND IS_SRVROLEMEMBER('sysadmin', name) = 1;
    QUERY
  end

  context 'Create an instance' do
    before(:context) do
      # Use a username with a space to test argument parsing works correctly
      @extra_admin_user = 'ExtraSQLAdmin'
      @user = Helper.instance.run_shell('$env:UserName').stdout.chomp
      pp = <<-MANIFEST
      user { '#{@extra_admin_user}':
        ensure => present,
        password => 'Puppet01!',
      }
      MANIFEST
      apply_manifest(pp, catch_failures: true)
    end

    after(:context) do
      pp = <<-MANIFEST
      user { '#{@extra_admin_user}':
        ensure => absent,
      }
      MANIFEST
      apply_manifest(pp, catch_failures: true)
    end

    inst_name = new_random_instance_name
    features = ['SQLEngine', 'Replication', 'FullText', 'DQ']

    it "create #{inst_name} instance" do
      host_computer_name = run_shell('CMD /C ECHO %COMPUTERNAME%').stdout.chomp
      ensure_sqlserver_instance(features, inst_name, 'present', ["#{host_computer_name}\\#{@extra_admin_user}"])

      validate_sql_install(version: version) do |r|
        expect(r.stdout).to match(%r{#{Regexp.new(inst_name)}})
      end
    end

    it "#{inst_name} instance has logged in user as an Administrator" do
      run_sql_query(run_sql_query_opts(inst_name, sql_query_is_user_sysadmin(@user), 1))
    end

    it "#{inst_name} instance has ExtraSQLAdmin as a sysadmin" do
      run_sql_query(run_sql_query_opts(inst_name, sql_query_is_user_sysadmin(@extra_admin_user), 1))
    end
    it "remove #{inst_name} instance" do
      ensure_sqlserver_instance(features, inst_name, 'absent')

      # Ensure all features for this instance are removed and the defaults are left alone
      validate_sql_install(version: version) do |r|
        expect(r.stdout).to match(%r{MSSQLSERVER\s+Database Engine Services})
        expect(r.stdout).to match(%r{MSSQLSERVER\s+SQL Server Replication})
        expect(r.stdout).to match(%r{MSSQLSERVER\s+Data Quality Services})
        expect(r.stdout).not_to match(%r{#{inst_name}\s+Database Engine Services})
        expect(r.stdout).not_to match(%r{#{inst_name}\s+SQL Server Replication})
        expect(r.stdout).not_to match(%r{#{inst_name}\s+Data Quality Services})
      end
    end
  end

  context "Feature has only one 'RS'" do
    inst_name = new_random_instance_name
    features = ['RS']

    after(:all) do
      ensure_sqlserver_instance(features, inst_name, 'absent')
    end

    it "create #{inst_name} instance with only one RS feature", unless: version.to_i >= 2017 do
      ensure_sqlserver_instance(features, inst_name)

      validate_sql_install(version: version) do |r|
        expect(r.stdout).to match(%r{#{inst_name}\s+Reporting Services})
      end
    end
  end
end
