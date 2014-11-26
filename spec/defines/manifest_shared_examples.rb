RSpec.shared_context 'manifests' do
  let(:title) { 'simple title' }
  let(:mssql_tsql_title) {}
  let(:params) { {} }
  let(:additional_params) { {} }
  let(:should_contain_command) { [] }
  let(:should_contain_onlyif) { [] }
  let(:should_not_contain_command) { [] }
  let(:should_not_contain_onlyif) { [] }
  let(:raise_error_check) {}
  let(:error_class) { Puppet::Error }

  def convert_to_regexp(str)
    return str if str.kind_of? Regexp
    Regexp.new(Regexp.escape(str))
  end

  shared_examples 'mssql_tsql onlyif' do
    it {
      params.merge!(additional_params)
      should_contain_onlyif.each do |check|
        should contain_mssql_tsql(mssql_tsql_title).with_onlyif(convert_to_regexp(check))
      end
    }

  end
  shared_examples 'mssql_tsql without_onlyif' do
    it {
      params.merge!(additional_params)
      should_not_contain_onlyif.each do |check|
        should contain_mssql_tsql(mssql_tsql_title).with_onlyif(convert_to_regexp(check))
      end
    }
  end

  shared_examples 'mssql_tsql command' do
    it {
      params.merge!(additional_params)
      should_contain_command.each do |check|
        should contain_mssql_tsql(mssql_tsql_title).with_command(convert_to_regexp(check))
      end
    }

  end
  shared_examples 'mssql_tsql without_command' do
    it {
      params.merge!(additional_params)
      should_not_contain_command.each do |check|
        should_not contain_mssql_tsql(mssql_tsql_title).with_command(convert_to_regexp(check))
      end
    }
  end
  shared_examples 'compile' do
    it {
      params.merge!(additional_params)
      should compile
    }
  end
  shared_examples 'validation error' do
    it {
      params.merge!(additional_params)
      expect { should compile }.to raise_error(error_class, convert_to_regexp(raise_error_check))

    }
  end
end
