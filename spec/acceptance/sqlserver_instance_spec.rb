require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one("sql_host")

def new_random_instance_name
  ("MSSQL" + SecureRandom.hex(4)).upcase.to_s
end

describe "sqlserver_instance", :node => host do
  version = host['sql_version'].to_s


  def ensure_sqlserver_instance(host, features, inst_name, ensure_val = 'present')
    manifest = <<-MANIFEST
    sqlserver_instance{'#{inst_name}':
      name                  => '#{inst_name}',
      ensure                => <%= ensure_val %>,
      source                => 'H:',
      features              => [ <%= mssql_features %> ],
      sql_sysadmin_accounts => ['Administrator'],
      agt_svc_account       => 'Administrator',
      agt_svc_password      => 'Qu@lity!',
    }
    MANIFEST

    mssql_features = features.map { |x| "'#{x}'" }.join(', ')

    pp = ERB.new(manifest).result(binding)

    apply_manifest_on(host, pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  context "Create an instance", {:testrail => ['88978', '89028', '89031', '89043', '89061']} do
    inst_name = new_random_instance_name
    features = ['SQL', 'SQLEngine', 'Replication', 'FullText', 'DQ']

    it "create #{inst_name} instance" do
      ensure_sqlserver_instance(host, features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{Regexp.new(inst_name)}/)
      end
    end

    it "remove #{inst_name} instance" do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')

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

  context "Feature has only one 'SQL'", {:testrail => ['89032']} do
    inst_name = new_random_instance_name
    features = ['SQL']

    after(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
    end

    it "create #{inst_name} instance with only one SQL feature" do
      ensure_sqlserver_instance(host, features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{inst_name}\s+Database Engine Services/)
        expect(r.stdout).to match(/#{inst_name}\s+SQL Server Replication/)
        expect(r.stdout).to match(/#{inst_name}\s+Data Quality Services/)
      end
    end
  end

  context "Feature has only one 'RS'", {:testrail => ['89034']} do
   inst_name = new_random_instance_name
   features = ['RS']

    after(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
    end

    it "create #{inst_name} instance with only one RS feature" do
      ensure_sqlserver_instance(host, features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{inst_name}\s+Reporting Services/)
      end
    end
  end

  context "Feature has only one 'AS'", {:testrail => ['89033']} do
    inst_name = new_random_instance_name
    features = ['AS']

    after(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
    end

    #skip below test due to ticket MODULES-2379, when the ticket was resolved
    # will change xit to it
    xit "create #{inst_name} instance with only one AS feature" do
      ensure_sqlserver_instance(host, features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{Regexp.new(inst_name)}/)
      end
    end
  end
end
