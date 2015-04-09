require 'spec_helper_acceptance'
require 'ERB'

%w(2012 2014).each do |version|
  host = find_only_one("sql#{version}")
  describe "sqlserver::login #{version}", :node => host do

    # An ERB template for a sqlserver::login
    manifest = <<-MANIFEST
    sqlserver::config{'MSSQLSERVER':
      admin_pass        => '<%= SQL_ADMIN_PASS %>',
      admin_user        => '<%= SQL_ADMIN_USER %>',
    }
    sqlserver::login{'<%= login_name %>':
      ensure            => <%= defined?(ensure_value) ? ensure_value : 'present' %>,
      password          => '<%= defined?(password) ? password : SQL_ADMIN_PASS %>',
      default_database  => '<%= defined?(default_database) ? default_database : 'master' %>',
      default_language  => '<%= defined?(default_language) ? default_language : 'us_english'%>',        disabled          => <%= defined?(disabled) ? disabled : false %>,
    }
    MANIFEST
    no_results_error = 'Expected 1 rows but observed 0'

    context 'create a sql login' do

      login_name = 'Gumby'

      after(:each) do
        opts = {:query => "DROP LOGIN #{login_name}", :no_rows_expected => true}

        # delete the login
        run_sql_query(host, opts) do |r|
          expect(r.stdout).not_to match(/Error/)
        end
      end

      it "should create a login" do
        name_query = "SELECT name FROM sys.server_principals WHERE name = '#{login_name}'"
        pp = ERB.new(manifest).result(binding)

        apply_manifest_on(host, pp) do |r|
          expect(r.stdout).not_to match(/Error/)
        end

        run_sql_query(host, {:query => name_query}) do |r|
          expect(r.stdout).not_to match(/Error/)
          expect(r.stdout).to match(/#{login_name}/)
        end
      end

    end

    context 'delete a login' do

      login_name = 'Pokey'

      before(:all) do
        pp = ERB.new(manifest).result(binding)

        # create the login needed for test
        apply_manifest_on(host, pp) do |r|
          expect(r.stdout).not_to match(/Error/)
        end
      end

      it 'removes an existing login' do
        ensure_value = 'absent'
        pp = ERB.new(manifest).result(binding)

        apply_manifest_on(host, pp) do |r|
          expect(r.stdout).not_to match(/Error/)
          expect{run_sql_query(host, {:query => query})}.to raise_error(RuntimeError, no_results_error)
        end
      end

    end

    context 'mutate a login' do

      login_name = 'Denali'
      db_fixture = 'professor_kapp'

      before(:all) do
        pp = ERB.new(manifest).result(binding)

        # create the login to test
        apply_manifest_on(host, pp) do |r|
          expect(r.stdout).not_to match(/Error/)
        end

        # create a DB to use as a fixture
        opts = {:query => "CREATE DATABASE #{db_fixture}", :no_rows_expected => true}
        run_sql_query(host, opts) do |r|
          expect(r.stdout).not_to match(/Error/)
        end
      end

      after(:all) do
        login_opts = {:query => "DROP LOGIN #{login_name}", :no_rows_expected => true}
        db_opts = {:query => "DROP DATABASE #{db_fixture}", :no_rows_expected => true}

        # delete the login
        run_sql_query(host, login_opts) do |r|
          expect(r.stdout).not_to match(/Error/)
        end

        # cleanup fixture DB
        run_sql_query(host, db_opts) do |r|
          expect(r.stdout).not_to match(/Error/)
        end
      end

      it 'disables the login' do
        disabled_query = "SELECT SP.is_disabled FROM sys.server_principals AS SP WHERE name = '#{login_name}'"
        disabled = true
        pp = ERB.new(manifest).result(binding)

        apply_manifest_on(host, pp) do |r|
          expect(r.stdout).not_to match(/Error/)
        end

        run_sql_query(host, {:query => disabled_query}) do |r|
          expect(r.stdout).not_to match(/Error/)
          expect(r.stdout).to match(/^1/)
        end
      end

      it 'changes the default database' do
        default_db_query = "SELECT SP.default_database_name FROM sys.server_principals AS SP WHERE name = '#{login_name}'"
        default_database = db_fixture
        pp = ERB.new(manifest).result(binding)

        apply_manifest_on(host, pp) do |r|
          expect(r.stdout).not_to match(/Error/)
        end

        run_sql_query(host, {:query => default_db_query}) do |r|
          expect(r.stdout).not_to match(/Error/)
          expect(r.stdout).to match(/#{db_fixture}/)
        end
      end

      it 'changes the default language' do
        language_query = "SELECT SP.default_language_name FROM sys.server_principals AS SP WHERE name = '#{login_name}'"
        default_language = 'german'
        pp = ERB.new(manifest).result(binding)

        apply_manifest_on(host, pp) do |r|
          expect(r.stdout).not_to match(/Error/)
        end

        run_sql_query(host, {:query => language_query}) do |r|
          expect(r.stdout).not_to match(/Error/)
          expect(r.stdout).to match(/#{default_language}/)
        end
      end

    end
  end
end
