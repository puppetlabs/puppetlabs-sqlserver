require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one("sql_host")

def new_random_instance_name
  ("MSSQL" + SecureRandom.hex(4)).upcase.to_s
end

describe "sqlserver_instance", :node => host do
  version = host['sql_version'].to_s

  def ensure_sqlserver_instance(features, inst_name, ensure_val = 'present', sysadmin_accounts = "['Administrator']")
    manifest = <<-MANIFEST
    sqlserver_instance{'#{inst_name}':
      name                  => '#{inst_name}',
      ensure                => <%= ensure_val %>,
      source                => 'H:',
      security_mode         => 'SQL',
      sa_pwd                => 'Pupp3t1@',
      features              => [ <%= mssql_features %> ],
      sql_sysadmin_accounts => #{sysadmin_accounts},
      agt_svc_account       => 'Administrator',
      agt_svc_password      => 'Qu@lity!',
      windows_feature_source => 'I:\\sources\\sxs',
    }
    MANIFEST

    mssql_features = features.map { |x| "'#{x}'" }.join(', ')

    pp = ERB.new(manifest).result(binding)

    execute_manifest(pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  #Return options for run_sql_query
  def run_sql_query_opts (inst_name, query, expected_row_count)
    run_sql_query_opt = {
        :query => query,
        :instance => inst_name,
        :server => '.',
        :sql_admin_user => 'sa',
        :sql_admin_pass => 'Pupp3t1@',
        :expected_row_count => expected_row_count,
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

  context "Create an instance", {:testrail => ['88978', '89028', '89031', '89043', '89061']} do

    before(:context) do
      @ExtraAdminUser = 'ExtraSQLAdmin'
      pp = <<-MANIFEST
      user { '#{@ExtraAdminUser}':
        ensure => present,
        password => 'Puppet01!',
      }
      MANIFEST
      execute_manifest(pp)
    end

    after(:context) do
      pp = <<-MANIFEST
      user { '#{@ExtraAdminUser}':
        ensure => absent,
      }
      MANIFEST
      execute_manifest(pp)
    end

    inst_name = new_random_instance_name
    features = ['SQLEngine', 'Replication', 'FullText', 'DQ']

    it "create #{inst_name} instance", :tier_low => true do
      ensure_sqlserver_instance(features, inst_name,'present',"['Administrator','ExtraSQLAdmin']")

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{Regexp.new(inst_name)}/)
      end
    end

    it "#{inst_name} instance has Administrator as a sysadmin", :tier_low => true do
      run_sql_query(host, run_sql_query_opts(inst_name, sql_query_is_user_sysadmin('Administrator'), expected_row_count = 1))
    end

    it "#{inst_name} instance has ExtraSQLAdmin as a sysadmin", :tier_low => true do
      run_sql_query(host, run_sql_query_opts(inst_name, sql_query_is_user_sysadmin('ExtraSQLAdmin'), expected_row_count = 1))
    end

    it "remove #{inst_name} instance", :tier_low => true do
      ensure_sqlserver_instance(features, inst_name, 'absent')

      # Ensure all features for this instance are removed and the defaults are left alone
      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/MSSQLSERVER\s+Database Engine Services/)
        expect(r.stdout).to match(/MSSQLSERVER\s+SQL Server Replication/)
        expect(r.stdout).to match(/MSSQLSERVER\s+Data Quality Services/)
        expect(r.stdout).not_to match(/#{inst_name}\s+Database Engine Services/)
        expect(r.stdout).not_to match(/#{inst_name}\s+SQL Server Replication/)
        expect(r.stdout).not_to match(/#{inst_name}\s+Data Quality Services/)
      end
    end
  end

  context "Feature has only one 'RS'", {:testrail => ['89034']} do
    inst_name = new_random_instance_name
    features = ['RS']

    after(:all) do
      ensure_sqlserver_instance(features, inst_name, 'absent')
    end

    it "create #{inst_name} instance with only one RS feature", :tier_low => true do
      ensure_sqlserver_instance(features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{inst_name}\s+Reporting Services/)
      end
    end
  end

  context "Feature has only one 'AS'", {:testrail => ['89033']} do
    inst_name = new_random_instance_name
    features = ['AS']

    after(:all) do
      ensure_sqlserver_instance(features, inst_name, 'absent')
    end

    #skip below test due to ticket MODULES-2379, when the ticket was resolved
    # will change xit to it
    xit "create #{inst_name} instance with only one AS feature" do
      ensure_sqlserver_instance(features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{Regexp.new(inst_name)}/)
      end
    end
  end
end
