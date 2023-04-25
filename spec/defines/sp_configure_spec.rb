# frozen_string_literal: true

require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::sp_configure', type: :define do
  include_context 'manifests' do
    let(:title) { 'filestream access level' }
    let(:sqlserver_tsql_title) { 'sp_configure-MSSQLSERVER-filestream access level' }
    let(:params) do
      {
        config_name: 'filestream access level',
        value: 1,
      }
    end
    let(:pre_condition) do
      <<-EOF
      define sqlserver::config{}
      sqlserver::config {'MSSQLSERVER': }
      EOF
    end
  end
  describe 'basic usage' do
    let(:should_contain_command) do
      [
        "EXECUTE @return_value = sp_configure @configname = N'filestream access level', @configvalue = 1",
        "IF @return_value != 0
	THROW 51000,'Unable to update `filestream access level`', 10",
        'RECONFIGURE',
      ]
    end
    let(:should_contain_onlyif) do
      [
        "IF EXISTS(SELECT * FROM sys.configurations WHERE name = 'filestream access level' AND value_in_use != 1)",
        "THROW 51000, 'sp_configure `filestream access level` is not in the correct state', 10",
      ]
    end

    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql onlyif'
  end

  describe 'reconfigure => false' do
    let(:additional_params) do
      {
        reconfigure: false,
      }
    end
    let(:should_not_contain_command) do
      [
        'RECONFIGURE WITH OVERRIDE',
        'RECONFIGURE',
      ]
    end

    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'reconfigure => invalid' do
    let(:additional_params) { { reconfigure: 'invalid' } }
    let(:raise_error_check) { "'reconfigure' expects a Boolean value" }

    it_behaves_like 'validation error'
  end

  describe 'restart => invalid' do
    let(:additional_params) { { restart: 'invalid' } }
    let(:raise_error_check) { "'restart' expects a Boolean value" }

    it_behaves_like 'validation error'
  end

  describe 'with_override => false' do
    let(:additional_params) do
      {
        with_override: false,
      }
    end
    let(:should_not_contain_command) do
      [
        'RECONFIGURE WITH OVERRIDE',
      ]
    end
    let(:should_contain_command) { ['RECONFIGURE'] }

    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'with_override => invalid' do
    let(:additional_params) { { with_override: 'invalid' } }
    let(:raise_error_check) { "'with_override' expects a Boolean value" }

    it_behaves_like 'validation error'
  end

  describe 'service' do
    it 'is defined' do
      is_expected.to contain_exec('restart-service-MSSQLSERVER-filestream access level').with_refreshonly(true)
    end
  end
end
