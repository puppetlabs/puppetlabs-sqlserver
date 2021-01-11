# frozen_string_literal: true

RSpec.shared_context 'manifests' do
  let(:title) { 'simple title' }
  let(:sqlserver_tsql_title) {}
  let(:params) { {} }
  let(:additional_params) { {} }
  let(:should_contain_command) { [] }
  let(:should_contain_onlyif) { [] }
  let(:should_not_contain_command) { [] }
  let(:should_not_contain_onlyif) { [] }
  let(:raise_error_check) {}
  let(:error_class) { Puppet::Error }

  def convert_to_regexp(str)
    return str if str.is_a? Regexp
    Regexp.new(Regexp.escape(str))
  end

  shared_examples 'sqlserver_tsql onlyif' do
    it {
      params.merge!(additional_params)
      should_contain_onlyif.each do |check|
        is_expected.to contain_sqlserver_tsql(sqlserver_tsql_title).with_onlyif(convert_to_regexp(check))
      end
    }
  end
  shared_examples 'sqlserver_tsql without_onlyif' do
    it {
      params.merge!(additional_params)
      should_not_contain_onlyif.each do |check|
        is_expected.to contain_sqlserver_tsql(sqlserver_tsql_title).with_onlyif(convert_to_regexp(check))
      end
    }
  end

  shared_examples 'sqlserver_tsql command' do
    it {
      params.merge!(additional_params)
      should_contain_command.each do |check|
        is_expected.to contain_sqlserver_tsql(sqlserver_tsql_title).with_command(convert_to_regexp(check))
      end
    }
  end

  shared_examples 'sqlserver_tsql without_command' do
    it {
      params.merge!(additional_params)
      should_not_contain_command.each do |check|
        is_expected.not_to contain_sqlserver_tsql(sqlserver_tsql_title).with_command(convert_to_regexp(check))
      end
    }
  end

  shared_examples 'compile' do
    it {
      params.merge!(additional_params)
      is_expected.to compile
    }
  end

  shared_examples 'validation error' do
    it {
      params.merge!(additional_params)
      expect { catalogue }.to raise_error(error_class, convert_to_regexp(raise_error_check))
    }
  end
end

def random_string_of_size(size, include_numeric = true)
  pool = [('a'..'z'), ('A'..'Z')]
  pool << (0..9) if include_numeric
  o = pool.map(&:to_a).flatten
  (0...size).map { o[rand(o.length)] }.join
end
