require 'spec_helper_acceptance'
require 'ERB'

host = find_only_one("sql_host")
describe "sqlserver_features", :node => host do
  version = host['sql_version'].to_s

  def ensure_sql_features(host, features, ensure_val = 'present')
    manifest = <<-MANIFEST
    sqlserver::config{ 'MSSQLSERVER':
      admin_pass        => '<%= SQL_ADMIN_PASS %>',
      admin_user        => '<%= SQL_ADMIN_USER %>',
    }
    sqlserver_features{ 'MSSQLSERVER':
      ensure            => <%= ensure_value %>,
      source            => 'H:',
      is_svc_account    => "$::hostname\\\\Administrator",
      is_svc_password   => 'Qu@lity!',
      features          => [ <%= mssql_features %> ],
    }
    MANIFEST

    ensure_value = ensure_val
    mssql_features = features.map{ |x| "'#{x}'"}.join(', ')

    pp = ERB.new(manifest).result(binding)

    apply_manifest_on(host, pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  context 'can install' do

    features = ['Tools', 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']

    before(:all) do
      remove_sql_features(host, {:features => features, :version => version})
    end

    after(:all) do
      remove_sql_features(host, {:features => features, :version => version})
    end

    it 'all possible features' do
      ensure_sql_features(host, features)

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

  context 'can remove' do

    features = ['Tools', 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']

    before(:all) do
      ensure_sql_features(host, features)
    end

    after(:all) do
      # redundant but necessary in case our manifest fails
      remove_sql_features(host, {:features => features, :version => version})
    end

    it 'all possible features' do
      ensure_sql_features(host, features, 'absent')

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

  context 'can remove aggregate feature' do

    all_possible_features = ['Tools', 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']
    aggregate_features = ['Tools', 'ADV_SSMS']

    before(:all) do
      remove_sql_features(host, {:features => all_possible_features, :version => version})
    end

    before(:each) do
      ensure_sql_features(host, aggregate_features)
    end

    after(:all) do
      # only aggregate should be installed, but wipe all in case manifest misbehaves
      remove_sql_features(host, {:features => all_possible_features, :version => version})
    end

    it "'Tools', which includes the 'Conn', 'SDK', 'BC', 'SSMS' and 'ADV_SSMS' features" do
      ensure_sql_features(host, ['Tools'], 'absent')

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Client Tools Connectivity/)
        expect(r.stdout).not_to match(/Client Tools SDK/)
        expect(r.stdout).not_to match(/Client Tools Backwards Compatibility/)
        expect(r.stdout).not_to match(/Management Tools - Basic/)
        expect(r.stdout).not_to match(/Management Tools - Complete/)
      end
    end

    it "'SSMS', which removes the dependent 'ADV_SSMS' feature" do
      ensure_sql_features(host, ['SSMS'], 'absent')

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).to_not match(/Management Tools - Basic/)
        expect(r.stdout).to_not match(/Management Tools - Complete/)
      end
    end

  end

  context 'can remove independent feature' do

    all_possible_features = ['Tools', 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']
    features = ['BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']

    before(:all) do
      remove_sql_features(host, {:features => all_possible_features, :version => version})
    end

    before(:each) do
      ensure_sql_features(host, features)
    end

    after(:all) do
      # only lower-level should be installed, but wipe all in case manifest misbehaves
      remove_sql_features(host, {:features => all_possible_features, :version => version})
    end

    it "'BC'" do
      ensure_sql_features(host, features - ['BC'])

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Client Tools Backwards Compatibility/)
      end
    end

    it "'Conn'" do
      ensure_sql_features(host, features - ['Conn'])

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Client Tools Connectivity/)
      end
    end

    it "'ADV_SSMS'" do
      ensure_sql_features(host, features - ['ADV_SSMS'])

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Management Tools - Complete/)

        # also verify SSMS is still present
        expect(r.stdout).to match(/Management Tools - Basic/)
      end
    end

    it "'SDK'" do
      ensure_sql_features(host, features - ['SDK'])

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Client Tools SDK/)
      end
    end

    it "'IS'" do
      ensure_sql_features(host, features - ['IS'])

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Integration Services/)
      end
    end

    it "'MDS'" do
      ensure_sql_features(host, features - ['MDS'])

      validate_sql_install(host, {:version => version}) do |r|
        expect(r.stdout).not_to match(/Master Data Services/)
      end
    end
  end

  context 'with negative test cases' do
    def bind_and_apply_failing_manifest(host, features, ensure_val = 'present')

      failing_manifest = <<-MANIFEST
      sqlserver::config{ 'MSSQLSERVER':
        admin_pass        => '<%= SQL_ADMIN_PASS %>',
        admin_user        => '<%= SQL_ADMIN_USER %>',
      }
      sqlserver_features{ 'MSSQLSERVER':
        ensure            => <%= ensure_value %>,
        source            => 'H:',
        is_svc_account    => "$::hostname\\\\Administrator",
        features          => [ <%= mssql_features %> ],
      }
      MANIFEST

      ensure_value = ensure_val
      mssql_features = features.map{ |x| "'#{x}'"}.join(', ')

      pp = ERB.new(failing_manifest).result(binding)

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).to match(/error/i)
      end
    end

    it 'fails when an is_svc_account is supplied and a password is not' do
      features = ['Tools', 'IS']
      bind_and_apply_failing_manifest(host, features)
    end

    it 'fails when ADV_SSMS is supplied but SSMS is not' do
      pending('This test is blocked by FM-2712')
      features = ['BC', 'Conn', 'ADV_SSMS', 'SDK']
      ensure_sql_features(host, features)
    end
  end
end
