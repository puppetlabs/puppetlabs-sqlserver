# frozen_string_literal: true

require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::database', type: :define do
  include_context 'manifests' do
    let(:title) { 'myTitle' }
    let(:sqlserver_tsql_title) { 'database-MSSQLSERVER-myTestDb' }
    let(:params) do
      {
        db_name: 'myTestDb',
        instance: 'MSSQLSERVER',
      }
    end
    let(:pre_condition) do
      <<-EOF
      define sqlserver::config{}
      sqlserver::config {'MSSQLSERVER': }
      EOF
    end
  end

  describe 'Minimal Params' do
    it_behaves_like 'compile'
  end

  describe 'Providing log filespec it should compile with valid log on params and' do
    it_behaves_like 'validation error' do
      let(:additional_params) { { log_filename: 'c:/test/logfile.ldf', log_name: 'myCrazyLog' } }
      let(:raise_error_check) { %r{(filespec_filename|filespec_name)} }
    end
    it_behaves_like 'validation error' do
      let(:additional_params) do
        {
          filespec_filename: 'c:/test/test.mdf',
        }
      end
      let(:raise_error_check) { %r{filespec_name must also be specified when specifying filespec_filename} }
    end
    describe 'filespec_name can not be more than 128 characters' do
      it_behaves_like 'validation error' do
        let(:additional_params) do
          {
            filespec_filename: 'c:/test/test.mdf',
            filespec_name: 'OMGthisISsoReallyLongAndBoringProcessImeanAReallyOMGthisISsoReallyLongAndBoringProcessMakeItOMGthisISsoReallyLongAndBoringProcess',
          }
        end
        let(:raise_error_check) { "'filespec_name' expects" }
      end
    end

    it_behaves_like 'sqlserver_tsql command' do
      let(:additional_params) do
        {
          filespec_filename: 'c:/test/test.mdf', filespec_name: 'myCre-Cre',
          log_filename: 'c:/test/logfile.ldf', log_name: 'myCrazy_Log'
        }
      end
      # Ensure that the parameters are in the TSQL and are correctly escaped
      let(:should_contain_command) do
        [
          %r{NAME = N'myCre-Cre'},
          %r{FILENAME = N'c:/test/test\.mdf'},
          %r{NAME = N'myCrazy_Log'},
          %r{FILENAME = N'c:/test/logfile\.ldf'},
        ]
      end
    end
  end

  describe 'collation_name' do
    let(:additional_params) { { collation_name: 'SQL_Latin1_General_CP1_CI_AS' } }
    let(:should_contain_command) do
      [
        %r{--\s*UPDATE SECTION.*ALTER\sDATABASE\s\[myTestDb\]\sCOLLATE\sSQL_Latin1_General_CP1_CI_AS}m,
        %r{--\s*CREATE SECTION.*IF\ NOT\ EXISTS\(SELECT\ name\ FROM\ sys\.databases\ WHERE\ name\ =\ 'myTestDb'\ AND\ collation_name\ =\ 'SQL_Latin1_General_CP1_CI_AS'\)}m,
        %r{--\s*UPDATE SECTION.*IF\ NOT\ EXISTS\(SELECT\ name\ FROM\ sys\.databases\ WHERE\ name\ =\ 'myTestDb'\ AND\ collation_name\ =\ 'SQL_Latin1_General_CP1_CI_AS'\)}m,
      ]
    end
    let(:should_contain_onlyif) do
      [
        "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND collation_name = 'SQL_Latin1_General_CP1_CI_AS')",
      ]
    end

    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql onlyif'
  end

  describe 'filestream failure' do
    let(:title) { 'myTitle' }
    let(:params) do
      {
        db_name: 'myTestDb',
        instance: 'MSSQLSERVER',
      }
    end

    it 'does not compile' do
      params[:filestream_directory_name] = 'C:/TestDirectory'
      expect {
        expect(subject).to contain_sqlserver_tsql('database-MSSQLSERVER-myTestDb')
      }.to raise_error(Puppet::Error)
    end
  end

  describe 'include filestream_non_transacted_access' do
    let(:additional_params) { { filestream_non_transacted_access: 'FULL' } }
    let(:should_contain_command) { [%r{FILESTREAM\s+\(\s+NON_TRANSACTED_ACCESS\s+=\s+FULL}] }
    let(:should_not_contain_command) { [%r{WITH\s*,\s*FILESTREAM}] }

    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'should not contain filestream by default' do
    let(:should_not_contain_command) { [%r{FILESTREAM}] }

    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'when adding filestream_directory_name' do
    let(:additional_params) { { filestream_directory_name: 'myDirName' } }
    let(:should_contain_command) do
      [
        %r{FILESTREAM\s*\(},
        %r{\(\s*DIRECTORY_NAME\s=\s'myDirName'},
      ]
    end
    let(:should_not_contain_command) { [%r{NON_TRANSACTED_ACCESS}] }

    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'partial parameters' do
    describe 'testing defaults and comma seperation' do
      let(:additional_params) { { containment: 'PARTIAL' } }
      let(:should_contain_command) do
        [
          %r{CONTAINMENT\s*=\s*PARTIAL}, # Should be stated after database
          %r{WITH\s*DB_CHAINING}m, # Should have no comma between, newlines are fine
          %r{DEFAULT_FULLTEXT_LANGUAGE=\[English\]\s*,}, # Should enclose default language of us_english in brackets
          %r{TRUSTWORTHY OFF\s*,},
          %r{-- CREATE.*TWO_DIGIT_YEAR_CUTOFF = 2049.*-- UPDATE}m,
        ]
      end
      let(:should_not_contain_command) do
        [
          %r{NESTED_TRIGGERS},
          %r{WITH\s*,\s*DB_CHAINING}m,
          %r{TRANSFORM_NOISE_WORDS},
          %r{FILESTREAM},
          %r{TWO_DIGIT_YEAR_CUTOFF = 2049\s*,},
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql without_command'
    end

    describe 'default_fulltext_language' do
      let(:additional_params) { { containment: 'PARTIAL', default_fulltext_language: 'us_english' } }
      let(:should_contain_command) { [%r{CONTAINMENT\s=\sPARTIAL}, %r{SET DEFAULT_FULLTEXT_LANGUAGE = \[us_english\]}, %r{,\s*DEFAULT_FULLTEXT_LANGUAGE=\[us_english\]}m] }

      it_behaves_like 'sqlserver_tsql command'
    end

    describe 'transform_noise_words ON' do
      let(:additional_params) { { containment: 'PARTIAL', transform_noise_words: 'ON' } }
      let(:should_contain_command) { [%r{CONTAINMENT\s=\sPARTIAL}, %r{,\s*TRANSFORM_NOISE_WORDS = ON}, %r{SET TRANSFORM_NOISE_WORDS = ON}, %r{is_transform_noise_words_on = 1}] }

      it_behaves_like 'sqlserver_tsql command'
    end

    describe 'transform_noise_words OFF' do
      let(:additional_params) { { containment: 'PARTIAL', transform_noise_words: 'OFF' } }
      let(:should_contain_command) { [%r{CONTAINMENT\s=\sPARTIAL}, %r{,\s*TRANSFORM_NOISE_WORDS = OFF}, %r{SET TRANSFORM_NOISE_WORDS = OFF}, %r{is_transform_noise_words_on = 0}] }

      it_behaves_like 'sqlserver_tsql command'
    end

    describe 'nested_triggers OFF' do
      let(:additional_params) { { containment: 'PARTIAL', nested_triggers: 'OFF' } }
      let(:should_contain_command) { [%r{CONTAINMENT\s=\sPARTIAL}, %r{NESTED_TRIGGERS = OFF}, %r{is_nested_triggers_on = 0}] }

      it_behaves_like 'sqlserver_tsql command'
    end

    describe 'nested_triggers ON' do
      let(:additional_params) { { containment: 'PARTIAL', nested_triggers: 'ON' } }
      let(:should_contain_command) { [%r{CONTAINMENT\s=\sPARTIAL}, %r{NESTED_TRIGGERS = ON}, %r{is_nested_triggers_on = 1}] }

      it_behaves_like 'sqlserver_tsql command'
    end

    describe 'trustworthy OFF' do
      let(:additional_params) { { containment: 'PARTIAL', trustworthy: 'OFF' } }
      let(:should_contain_command) { [%r{CONTAINMENT\s=\sPARTIAL}, %r{,\s*TRUSTWORTHY OFF}, %r{SET TRUSTWORTHY OFF}, %r{is_trustworthy_on = 0}] }

      it_behaves_like 'sqlserver_tsql command'
    end

    describe 'trustwothy ON' do
      let(:additional_params) { { containment: 'PARTIAL', trustworthy: 'ON' } }
      let(:should_contain_command) do
        [
          %r{CONTAINMENT\s=\sPARTIAL},
          %r{,\s*TRUSTWORTHY ON},
          %r{SET TRUSTWORTHY ON},
          %r{is_trustworthy_on = 1},
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND is_trustworthy_on = 1)",
        ]
      end
      let(:should_contain_onlyif) do
        [
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND containment_desc = 'PARTIAL')",
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND is_trustworthy_on = 1)",
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end

    describe 'db_chainging ON' do
      let(:additional_params) { { containment: 'PARTIAL', db_chaining: 'ON' } }
      let(:should_contain_command) do
        [
          %r{CONTAINMENT\s=\sPARTIAL},
          %r{WITH\s*DB_CHAINING ON},
          %r{SET DB_CHAINING ON},
          %r{is_db_chaining_on = 1},
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND is_db_chaining_on = 1)",
          'ALTER DATABASE [myTestDb] SET DB_CHAINING ON',
        ]
      end
      let(:should_contain_onlyif) do
        [
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND containment_desc = 'PARTIAL')",
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND is_db_chaining_on = 1)",
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end

    describe 'db_chainging OFF' do
      let(:additional_params) { { containment: 'PARTIAL', db_chaining: 'OFF' } }
      let(:should_contain_command) do
        [
          %r{CONTAINMENT\s=\sPARTIAL},
          %r{WITH\s*DB_CHAINING OFF},
          %r{SET DB_CHAINING OFF},
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND is_db_chaining_on = 0)",
          'ALTER DATABASE [myTestDb] SET DB_CHAINING OFF',
        ]
      end
      let(:should_contain_onlyif) do
        [
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND containment_desc = 'PARTIAL')",
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND is_db_chaining_on = 0)",
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
  end
end
