require 'spec_helper_acceptance'
require 'ERB'

host = find_only_one("sql_host")
describe "sqlserver_features", :node => host do
  version = host['sql_version'].to_s
  manifest = <<-MANIFEST
sqlserver::config{ 'MSSQLSERVER':
  admin_pass        => '<%= SQL_ADMIN_PASS %>',
  admin_user        => '<%= SQL_ADMIN_USER %>',
}
sqlserver_features{ 'MSSQLSERVER':
  ensure            => <%= defined?(ensure_value) ? ensure_value : 'present' %>,
  source            => 'H:',
  is_svc_account    => "$::hostname\\\\Administrator",
  is_svc_password   => 'Qu@lity!',
  features          => [ <%= mssql_features.map{ |x| "'" << x << "'"}.join(', ') %> ],
}
MANIFEST

  context 'installing all possible features' do

    mssql_features = ['Tools', 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']

    after(:all) do
      # remove the features
      remove_sql_features(host, {:features => mssql_features, :version => version})
    end

    it 'installs all possible features' do
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/Management Tools - Basic/)
        expect(r.stdout).to match(/Management Tools - Complete/)
        expect(r.stdout).to match(/Client Tools Connectivity/)
        expect(r.stdout).to match(/Client Tools Backwards Compatibility/)
        expect(r.stdout).to match(/Client Tools SDK/)
        expect(r.stdout).to match(/Integration Services/)
        expect(r.stdout).to match(/Master Data Services/)
      end
    end

  end

  context 'removing all possible features' do

    mssql_features = ['Tools', 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']

    before(:all) do
      # install all possible features
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end
    end

    it 'removes all the features' do
      ensure_value = 'absent'
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end

      validate_sql_install(host, {:version => version}) do |r|
      expect(r.stdout).not_to match(/Management Tools - Basic/)
      expect(r.stdout).not_to match(/Management Tools - Complete/)
      expect(r.stdout).not_to match(/Client Tools Connectivity/)
      expect(r.stdout).not_to match(/Client Tools Backwards Compatibility/)
      expect(r.stdout).not_to match(/Client Tools SDK/)
      expect(r.stdout).not_to match(/Integration Services/)
      expect(r.stdout).not_to match(/Master Data Services/)
    end
  end
end

  context 'removing single features (top level)' do

    before(:all) do
      # remove all possible features (top level and lower level)
      all_possible_features = ['Tools', 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']
      remove_sql_features(host, {:features => all_possible_features, :version => version})
    end

    before(:each) do
      # install all possible (top level) features
      mssql_features = ['Tools', 'IS', 'MDS']

      pp = ERB.new(manifest).result(binding)
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end
    end

    after(:all) do
      all_possible_features = ['Tools', 'IS', 'MDS']
      # remove all possible features
      remove_sql_features(host, {:features => all_possible_features, :version => version})
    end

    it "removes the 'Tools' feature" do
      mssql_features = ['IS', 'MDS']
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Management Tools - Basic/)
        expect(r.stdout).not_to match(/Management Tools - Complete/)
        expect(r.stdout).not_to match(/Client Tools Connectivity/)
        expect(r.stdout).not_to match(/Client Tools Backwards Compatibility/)
      end
    end

    it "removes the 'IS' feature" do
      mssql_features = ['Tools', 'MDS']
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Client Tools SDK/)
      end
    end

    it "removes the 'MDS' feature" do
      mssql_features = ['Tools', 'IS']
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Master Data Services/)
      end
    end
  end

  context 'removing single feature (lower level)' do
    before(:all) do
      # remove all possible features (top level and lower level)
      all_possible_features = ['Tools', 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']
      remove_sql_features(host, {:features => all_possible_features, :version => version})
    end

    before(:each) do
      #install all possible lower level features
      mssql_features = ['BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK']
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end
    end

    after(:all) do
      # remove all features
      all_possible_features = ['BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK']
      remove_sql_features(host, {:features => all_possible_features, :version => version})
    end

    it "removes the 'BC' feature" do
      mssql_features = ['Conn', 'SSMS', 'ADV_SSMS', 'SDK']
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Client Tools Backwards Compatibility/)
      end
    end

    it "removes the 'Conn' feature" do
      mssql_features = ['BC', 'SSMS', 'ADV_SSMS', 'SDK']
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Client Tools Connectivity/)
      end
    end

    it "removes the 'SSMS' & 'ADV_SSMS' features" do
      mssql_features = ['BC', 'Conn', 'SDK']
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to_not match(/Management Tools - Basic/)
        expect(r.stdout).to_not match(/Management Tools - Complete/)
      end
    end

    it "removes the 'ADV_SSMS' feature" do
      mssql_features = ['BC', 'Conn', 'SSMS', 'SDK']
      pp = ERB.new(manifest).result(binding)
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/)
      end

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to match(/Management Tools - Basic/)
        expect(r.stdout).not_to match(/Management Tools - Complete/)
      end
    end

    it "removes the 'SDK' feature" do
      mssql_features = ['BC', 'Conn', 'SSMS', 'ADV_SSMS']
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/error/i)
      end

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Client Tools SDK/)
      end
    end
  end

  context 'negative test cases' do

    failing_manifest = <<-MANIFEST
sqlserver::config{ 'MSSQLSERVER':
  admin_pass        => '<%= SQL_ADMIN_PASS %>',
  admin_user        => '<%= SQL_ADMIN_USER %>',
}
sqlserver_features{ 'MSSQLSERVER':
  ensure            => <%= defined?(ensure_value) ? ensure_value : 'present' %>,
  source            => 'H:',
  is_svc_account    => "$::hostname\\\\Administrator",
  features          => [ <%= mssql_features.map{ |x| "'" << x << "'"}.join(', ') %> ],
}
MANIFEST

    it 'fails when an is_svc_account is supplied and a password is not' do
      mssql_features = ['Tools', 'IS']
      pp = ERB.new(failing_manifest).result(binding)
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).to match(/error/i)
      end
    end

    it 'fails when ADV_SSMS is supplied but SSMS is not' do
      pending('This test is blocked by FM-2712')
      mssql_features = ['BC', 'Conn', 'ADV_SSMS', 'SDK']
      pp = ERB.new(manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).to match(/error/i)
      end
    end
  end
end
