require 'spec_helper_acceptance'
require 'erb'
require 'json'

version = sql_version?

describe 'sqlserver_features', if: version.to_i != 2012 do
  def ensure_sql_features(features, ensure_val = 'present')
    pp = <<-MANIFEST
    sqlserver::config{ 'MSSQLSERVER':
      admin_pass        => '<%= SQL_ADMIN_PASS %>',
      admin_user        => '<%= SQL_ADMIN_USER %>',
    }
    sqlserver_features{ 'MSSQLSERVER':
      ensure            => #{ensure_val},
      source            => 'H:',
      is_svc_account    => "$::hostname\\\\Administrator",
      is_svc_password   => 'Qu@lity!',
      features          => #{features},
      windows_feature_source => 'I:\\sources\\sxs',
    }
    MANIFEST

    apply_manifest(pp, catch_failures: true)
  end

  def bind_and_apply_failing_manifest(features, ensure_val = 'present')
    pp = <<-MANIFEST
    sqlserver::config{ 'MSSQLSERVER':
      admin_pass        => '<%= SQL_ADMIN_PASS %>',
      admin_user        => '<%= SQL_ADMIN_USER %>',
    }
    sqlserver_features{ 'MSSQLSERVER':
      ensure            => #{ensure_val},
      source            => 'H:',
      is_svc_account    => "$::hostname\\\\Administrator",
      features          => #{features},
    }
    MANIFEST

    apply_manifest(pp, expect_failures: true)
  end

  context 'can install' do
    features = if version.to_i >= 2016
                 ['BC', 'Conn', 'SDK', 'IS', 'MDS', 'DQC']
               else
                 ['BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS', 'DQC']
               end

    before(:all) do
      ensure_sql_features(features, 'absent')
    end

    it 'all possible features' do
      ensure_sql_features(features)

      validate_sql_install(version: version) do |r|
        expect(r.stdout).to match(%r{Client Tools Connectivity})
        expect(r.stdout).to match(%r{Client Tools Backwards Compatibility})
        expect(r.stdout).to match(%r{Client Tools SDK})
        expect(r.stdout).to match(%r{Integration Services})
        expect(r.stdout).to match(%r{server Data Services})
      end
    end
  end

  context 'can remove' do
    features = if version.to_i >= 2016
                 ['BC', 'Conn', 'SDK', 'IS', 'MDS', 'DQC']
               else
                 ['BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS', 'DQC']
               end

    it 'all possible features' do
      ensure_sql_features(features, 'absent')

      validate_sql_install(version: version) do |r|
        expect(r.stdout).not_to match(%r{Client Tools Connectivity})
        expect(r.stdout).not_to match(%r{Client Tools Backwards Compatibility})
        expect(r.stdout).not_to match(%r{Client Tools SDK})
        expect(r.stdout).not_to match(%r{Integration Services})
        expect(r.stdout).not_to match(%r{server Data Services})
      end
    end
  end

  context 'can remove independent feature' do
    features = if version.to_i >= 2016
                 ['BC', 'Conn', 'SDK', 'IS', 'MDS', 'DQC']
               else
                 ['BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS', 'DQC']
               end

    before(:all) do
      ensure_sql_features(features)
    end

    after(:all) do
      ensure_sql_features(features, 'absent')
    end

    it "'BC'" do
      ensure_sql_features(features - ['BC'])

      validate_sql_install(version: version) do |r|
        expect(r.stdout).not_to match(%r{Client Tools Backwards Compatibility})
      end
    end

    it "'ADV_SSMS'", unless: version.to_i >= 2016 do
      ensure_sql_features(features - ['ADV_SSMS'])

      validate_sql_install(version: version) do |r|
        expect(r.stdout).not_to match(%r{Management Tools - Complete})

        # also verify SSMS is still present
        expect(r.stdout).to match(%r{Management Tools - Basic})
      end
    end

    it "'SDK' + 'IS" do
      ensure_sql_features(features - ['SDK', 'IS'])

      validate_sql_install(version: version) do |r|
        expect(r.stdout).not_to match(%r{Client Tools SDK})
      end
    end
  end

  context 'with negative test cases' do
    it 'fails when an is_svc_account is supplied and a password is not' do
      features = ['IS']
      bind_and_apply_failing_manifest(features)
    end

    it 'fails when ADV_SSMS is supplied but SSMS is not - FM-2712' do
      pending('error not shown on Sql Server 2014') if version .to_i == 2014
      features = ['BC', 'Conn', 'ADV_SSMS', 'SDK']
      bind_and_apply_failing_manifest(features)
    end
  end

  context 'with no installed instances' do
    # Currently this test can only be run on a machine once and will error if run a second time
    context 'can install' do
      features = ['BC', 'Conn', 'SDK', 'IS', 'MDS', 'DQC']

      def remove_sql_instance
        pp = <<-MANIFEST
            sqlserver_instance{'MSSQLSERVER':
            ensure                => absent,
            source                => 'H:',
            sql_sysadmin_accounts => ['Administrator'],
            }
            MANIFEST
        idempotent_apply(pp)
      end

      before(:all) do
        remove_sql_instance
      end

      after(:all) do
        ensure_sql_features(features, 'absent')
      end

      it 'all possible features' do
        ensure_sql_features(features)

        validate_sql_install(version: version) do |r|
          # SQL Server 2016 will not install the client tools features.
          expect(r.stdout).not_to match(%r{MSSQLSERVER\s+Database Engine Services})
          expect(r.stdout).not_to match(%r{MSSQLSERVER\s+SQL Server Replication})
          expect(r.stdout).not_to match(%r{MSSQLSERVER\s+Data Quality Services})
          expect(r.stdout).to match(%r{Client Tools Connectivity}) unless version.to_i >= 2016
          expect(r.stdout).to match(%r{Client Tools Backwards Compatibility}) unless version.to_i >= 2016
          expect(r.stdout).to match(%r{Client Tools SDK}) unless version.to_i >= 2016
          expect(r.stdout).to match(%r{Integration Services})
          expect(r.stdout).to match(%r{server Data Services})
        end
      end
    end
  end
end
