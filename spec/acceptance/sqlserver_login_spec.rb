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
      query = "SELECT name FROM sys.server_principals WHERE name = '#{login_name}'"

      after(:each) do
        # delete the login
        opts = {
          :query              => "DROP LOGIN #{login_name}",
          :no_rows_expected   => true,
        }
        r = run_sql_query(host, opts)
        expect(r.stdout).not_to match(/Error/)
      end

      it "should create a login" do
        pp = ERB.new(manifest).result(binding)
        r = apply_manifest_on(host, pp)
        expect(r.stdout).not_to match(/Error/)
        sql_result = run_sql_query(host, {:query => query})
        expect(sql_result.stdout).not_to match(/Error/)
        expect(sql_result.stdout).to match(/#{login_name}/)
      end

    end

    context 'delete a login' do

      login_name = 'Pokey'
      query = "SELECT name FROM sys.server_principals WHERE name = '#{login_name}'"

      before(:all) do
        # create the login needed for test
        pp = ERB.new(manifest).result(binding)
        r = apply_manifest_on(host, pp)
        expect(r.stdout).not_to match(/Error/)
        sql_result = run_sql_query(host, {:query => query})
        expect(sql_result.stdout).not_to match(/Error/)
        expect(sql_result.stdout).to match(/#{login_name}/)
      end

      it 'removes an existing login' do
        ensure_value = 'absent'
        pp = ERB.new(manifest).result(binding)
        r = apply_manifest_on(host, pp)
        expect(r.stdout).not_to match(/Error/)
        expect{run_sql_query(host, {:query => query})}.to raise_error(RuntimeError, no_results_error)
      end

    end

    context 'mutate a login' do

      login_name = 'Denali'
      db_fixture = 'professor_kapp'
      query = "SELECT name FROM sys.server_principals WHERE name = '#{login_name}'"

      before(:all) do
        # create the login to test
        pp = ERB.new(manifest).result(binding)
        r = apply_manifest_on(host, pp)
        expect(r.stdout).not_to match(/Error/)
        sql_result = run_sql_query(host, {:query => query})
        expect(sql_result.stdout).not_to match(/Error/)
        expect(sql_result.stdout).to match(/#{login_name}/)
        # create a DB to use as a fixture
        opts = {
          :query              => "CREATE DATABASE #{db_fixture}",
          :no_rows_expected   => true,
        }
        run_sql_query(host, opts)
      end

      after(:all) do
        # delete the login
        login_opts = {
          :query              => "DROP LOGIN #{login_name}",
          :no_rows_expected   => true,
        }
        r = run_sql_query(host, login_opts)
        expect(r.stdout).not_to match(/Error/)
        # cleanup fixture DB
        db_opts = {
          :query              => "DROP DATABASE #{db_fixture}",
          :no_rows_expected   => true,
        }
        sql_result = run_sql_query(host, db_opts)
      end

      it 'disables the login' do
        disabled_query = "SELECT SP.is_disabled FROM sys.server_principals AS SP WHERE name = '#{login_name}'"
        disabled = true
        pp = ERB.new(manifest).result(binding)
        r = apply_manifest_on(host, pp)
        expect(r.stdout).not_to match(/Error/)
        sql_result = run_sql_query(host, {:query => disabled_query})
        expect(sql_result.stdout).not_to match(/Error/)
        expect(sql_result.stdout).to match(/^1/)
      end

      it 'changes the default database' do
        default_db_query = "SELECT SP.default_database_name FROM sys.server_principals AS SP WHERE name = '#{login_name}'"
        default_database = db_fixture
        pp = ERB.new(manifest).result(binding)
        r = apply_manifest_on(host, pp)
        expect(r.stdout).not_to match(/Error/)
        sql_result = run_sql_query(host, {:query => default_db_query})
        expect(sql_result.stdout).not_to match(/Error/)
        expect(sql_result.stdout).to match(/#{db_fixture}/)
      end

      it 'changes the default language' do
        language_query = "SELECT SP.default_language_name FROM sys.server_principals AS SP WHERE name = '#{login_name}'"
        default_language = 'german'
        pp = ERB.new(manifest).result(binding)
        r = apply_manifest_on(host, pp)
        expect(r.stdout).not_to match(/Error/)
        sql_result = run_sql_query(host, {:query => language_query})
        expect(sql_result.stdout).not_to match(/Error/)
        expect(sql_result.stdout).to match(/#{default_language}/)
      end

    end
  end
end
