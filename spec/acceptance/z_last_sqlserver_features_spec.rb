require 'spec_helper_acceptance'
require 'erb'
require 'json'

host = find_only_one("sql_host")
describe "sqlserver_features", :node => host do
  sql_version = host['sql_version'].to_s

  def ensure_sql_features(features, ensure_val = 'present')
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
      windows_feature_source => 'I:\\sources\\sxs',
    }
    MANIFEST

    ensure_value = ensure_val
    mssql_features = features.map { |x| "'#{x}'" }.join(', ')

    pp = ERB.new(manifest).result(binding)

    execute_manifest(pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  context 'can install' do
    features = ['BC', 'Conn', 'SDK', 'IS', 'MDS']

    before(:all) do
      remove_sql_features(host, {:features => features, :version => sql_version})
    end

    after(:all) do
      remove_sql_features(host, {:features => features, :version => sql_version})
    end

    it 'all possible features', :tier_low => true do
      ensure_sql_features(features)

      validate_sql_install(host, {:version => sql_version}) do |r|
        expect(r.stdout).to match(/Client Tools Connectivity/)
        expect(r.stdout).to match(/Client Tools Backwards Compatibility/)
        expect(r.stdout).to match(/Client Tools SDK/)
        expect(r.stdout).to match(/Integration Services/)
        expect(r.stdout).to match(/Master Data Services/)
      end
    end
  end

  context 'can remove' do

    features = ['BC', 'Conn', 'SDK', 'IS', 'MDS']

    before(:all) do
      ensure_sql_features(features)
    end

    after(:all) do
      # redundant but necessary in case our manifest fails
      remove_sql_features(host, {:features => features, :version => sql_version})
    end

    it 'all possible features', :tier_low => true do
      ensure_sql_features(features, 'absent')

      validate_sql_install(host, {:version => sql_version}) do |r|
        expect(r.stdout).not_to match(/Client Tools Connectivity/)
        expect(r.stdout).not_to match(/Client Tools Backwards Compatibility/)
        expect(r.stdout).not_to match(/Client Tools SDK/)
        expect(r.stdout).not_to match(/Integration Services/)
        expect(r.stdout).not_to match(/Master Data Services/)
      end
    end
  end


  context 'can remove independent feature' do
    if sql_version == '2016'
      all_possible_features = ['BC', 'Conn', 'SDK', 'IS', 'MDS']
      features = ['BC', 'Conn', 'SDK', 'IS', 'MDS']
    else
      all_possible_features = ['BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']
      features = ['BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS']
    end

    before(:all) do
      remove_sql_features(host, {:features => all_possible_features, :version => sql_version})
    end

    before(:each) do
      ensure_sql_features(features)
    end

    after(:all) do
      # only lower-level should be installed, but wipe all in case manifest misbehaves
      remove_sql_features(host, {:features => all_possible_features, :version => sql_version})
    end

    it "'BC'", :tier_low => true do
      ensure_sql_features(features - ['BC'])

      validate_sql_install(host, {:version => sql_version}) do |r|
        expect(r.stdout).not_to match(/Client Tools Backwards Compatibility/)
      end
    end

    it "'Conn'", :tier_low => true do
      ensure_sql_features(features - ['Conn'])

      validate_sql_install(host, {:version => sql_version}) do |r|
        expect(r.stdout).not_to match(/Client Tools Connectivity/)
      end
    end

    # TODO: Guard on SQL 2016 and 2017
    it "'ADV_SSMS'", :unless => sql_version.to_i >= 2016, :tier_low => true do
      ensure_sql_features(features - ['ADV_SSMS'])

      validate_sql_install(host, {:version => sql_version}) do |r|
        expect(r.stdout).not_to match(/Management Tools - Complete/)

        # also verify SSMS is still present
        expect(r.stdout).to match(/Management Tools - Basic/)
      end
    end

    it "'SDK'", :tier_low => true do
      ensure_sql_features(features - ['SDK'])

      validate_sql_install(host, {:version => sql_version}) do |r|
        expect(r.stdout).not_to match(/Client Tools SDK/)
      end
    end

    it "'IS'", :tier_low => true do
      ensure_sql_features(features - ['IS'])

      validate_sql_install(host, {:version => sql_version}) do |r|
        expect(r.stdout).not_to match(/Integration Services/)
      end
    end

    it "'MDS'", :tier_low => true do
      ensure_sql_features(features - ['MDS'])

      validate_sql_install(host, {:version => sql_version}) do |r|
        expect(r.stdout).not_to match(/Master Data Services/)
      end
    end
  end

  context 'with negative test cases' do
    def bind_and_apply_failing_manifest(features, ensure_val = 'present')

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
      mssql_features = features.map { |x| "'#{x}'" }.join(', ')

      pp = ERB.new(failing_manifest).result(binding)

      execute_manifest(pp) do |r|
        expect(r.stderr).to match(/error/i)
      end
    end

    it 'fails when an is_svc_account is supplied and a password is not', :tier_low => true do
      features = ['IS']
      bind_and_apply_failing_manifest(features)
    end

    it 'fails when ADV_SSMS is supplied but SSMS is not', :tier_low => true do
      skip('This test is blocked by FM-2712')
      features = ['BC', 'Conn', 'ADV_SSMS', 'SDK']
      ensure_sql_features(features)
    end
  end

  context 'with no installed instances' do

    context 'can install' do

      features = ['BC', 'Conn', 'SDK', 'IS', 'MDS']

      before(:all) do
        puppet_version = (on host, puppet('--version')).stdout.chomp
        json_result = JSON.parse((on host, puppet('facts --render-as json')).raw_output)["values"]["sqlserver_instances"]
        names = json_result.collect { |k, v| json_result[k].keys }.flatten
        remove_sql_instances(host, {:version => sql_version, :instance_names => names})
      end

      after(:all) do
        remove_sql_features(host, {:features => features, :version => sql_version})
      end

      it 'all possible features', :tier_low => true do
        ensure_sql_features(features)

        validate_sql_install(host, {:version => sql_version}) do |r|
          # SQL Server 2016 will not install the client tools features.
          expect(r.stdout).to match(/Client Tools Connectivity/) unless sql_version.to_i >= 2016
          expect(r.stdout).to match(/Client Tools Backwards Compatibility/) unless sql_version.to_i >= 2016
          expect(r.stdout).to match(/Client Tools SDK/) unless sql_version.to_i >= 2016
          expect(r.stdout).to match(/Integration Services/)
          expect(r.stdout).to match(/Master Data Services/)
        end
      end
    end
  end
end
