require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one("sql_host")
inst_name = "MSSQL" + SecureRandom.hex(4)
inst_name = inst_name.upcase

describe "sqlserver_instance", :node => host do
  version = host['sql_version'].to_s

  def ensure_sqlserver_instance(host, features, inst_name, ensure_val = 'present')
    manifest = <<-MANIFEST
    sqlserver_instance{'#{inst_name}':
      name                  => '#{inst_name}',
      ensure                => <%= ensure_value %>,
      source                => 'H:',
      features              => [ <%= mssql_features %> ],
      sql_sysadmin_accounts => ['Administrator'],
      agt_svc_account       => 'Administrator',
      agt_svc_password      => 'Qu@lity!',
    }
    MANIFEST

    ensure_value    = ensure_val
    mssql_features  = features.map{ |x| "'#{x}'"}.join(', ')

    pp = ERB.new(manifest).result(binding)

    apply_manifest_on(host, pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  context "can create sqlserver instance: #{inst_name}" do

    features = ['SQL', 'SQLEngine', 'Replication', 'FullText', 'DQ']

    before(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
      remove_sql_features(host, {:features => features, :version => version})
    end

    after(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
      remove_sql_features(host, {:features => features, :version => version})
    end

    it "create #{inst_name} instance" do
      ensure_sqlserver_instance(host, features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{Regexp.new(inst_name)}/)
      end
    end

    it "remove #{inst_name} instance" do
      remove_sql_features(host, {:features => features, :version => version})
      ensure_sqlserver_instance(host, features, inst_name, 'absent')

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/#{Regexp.new(inst_name)}/)
      end
    end
  end

  context "can create instance with only SQL feature" do
    features = ['SQL']

    before(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
      remove_sql_features(host, {:features => features, :version => version})
    end

    after(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
      remove_sql_features(host, {:features => features, :version => version})
    end

    it "create #{inst_name} instance with only SQL feature" do
      ensure_sqlserver_instance(host, features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{Regexp.new(inst_name)}/)
      end
    end
  end

  context "can create instance with only RS feature" do
    features = ['RS']

    before(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
      remove_sql_features(host, {:features => features, :version => version})
    end

    after(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
      remove_sql_features(host, {:features => features, :version => version})
    end

    it "create #{inst_name} instance with only RS feature" do
      ensure_sqlserver_instance(host, features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{Regexp.new(inst_name)}/)
      end
    end
  end

  context "can create instance with only AS feature" do
    features = ['AS']

    before(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
      remove_sql_features(host, {:features => features, :version => version})
    end

    after(:all) do
      ensure_sqlserver_instance(host, features, inst_name, 'absent')
      remove_sql_features(host, {:features => features, :version => version})
    end

    #skip below test due to ticket MODULES-2379, when the ticket was resolved
    # will change xit to it
    xit "create #{inst_name} instance with only AS feature" do
      ensure_sqlserver_instance(host, features, inst_name)

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/#{Regexp.new(inst_name)}/)
      end
    end
  end

end
