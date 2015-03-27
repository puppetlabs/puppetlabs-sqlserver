require 'spec_helper_acceptance'

RSpec.shared_context 'sqlcmd_context' do
  let(:sql_admin_user) { 'sa' }
  let(:sql_admin_pass) { 'Pupp3t1@' }
  let(:sqlcmd_path) { 'sqlcmd.exe' }
  let(:host) { default }
  let(:query) { '' }
  let(:should_result) { '' }
  let(:row_count) { 1 }
  RSpec.shared_examples 'query result' do
    it {
      tmpfile = host.tmpfile('should_contain_query.sql')
      create_remote_file(host, tmpfile, query + "\n")
      tmpfile.gsub!("/", "\\")
      sqlcmd_query = <<-sql_query
 sqlcmd.exe -U #{sql_admin_user} -P #{sql_admin_pass} -h-1 -W -s "|" -i \"#{tmpfile}\"
      sql_query
      on host, sqlcmd_query, :environment => {"PATH" => '/cygdrive/c/Program Files/Microsoft SQL Server/Client SDK/ODBC/110/Tools/Binn:/cygdrive/c/Program Files/Microsoft SQL Server/110/Tools/Binn'} do |result|
        assert_match(Regexp.new(should_result), result.stdout)
        assert_match(Regexp.new("#{row_count} rows affected"), result.stdout, "Expected to have row count matching #{row_count}")
      end
    }
  end


end
