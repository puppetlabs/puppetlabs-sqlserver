require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'mssql::database', :type => :define do
  include_context 'manifests' do
    let(:title) { 'myTitle' }
    let(:mssql_tsql_title) { 'database-MSSQLSERVER-myTestDb' }
    let(:params) { {
        :db_name => 'myTestDb',
        :instance => 'MSSQLSERVER',
    } }
  end

  describe 'Minimal Params' do
    it_behaves_like 'mssql_tsql command'
  end

  describe 'Providing log filespec it should compile with valid log on params and' do
    it_behaves_like 'validation error' do
      let(:additional_params) { {:log_filename => "c:/test/logfile.ldf", :log_name => "myCrazyLog"} }
      let(:raise_error_check) { 'filespec_name and filespec_filename must be specified when specifying any log attributes' }
    end
    it_behaves_like 'validation error' do
      let(:additional_params) { {
          :filespec_filename => 'c:/test/test.mdf'} }
      let(:raise_error_check) { 'filespec_name must not be null if specifying filespec_filename' }
    end
    describe 'filespec_name can not be more than 128 characters' do
      it_behaves_like 'validation error' do
        let(:additional_params) { {
            :filespec_filename => 'c:/test/test.mdf',
            :filespec_name =>
                'OMGthisISsoReallyLongAndBoringProcessImeanAReallyOMGthisISsoReallyLongAndBoringProcessMakeItOMGthisISsoReallyLongAndBoringProcess'} }
        let(:raise_error_check) { 'filespec_name can not be more than 128 characters' }
      end
    end
    it_behaves_like 'mssql_tsql command' do
      let(:additional_params) { {
          :filespec_filename => 'c:/test/test.mdf', :filespec_name => 'myCreCre',
          :log_filename => "c:/test/logfile.ldf", :log_name => "myCrazyLog"} }
      let(:should_contain_command) { [/c\:\/test\/logfile\.ldf/] }
    end
  end
  describe 'collation_name' do
    let(:additional_params) { {:collation_name => 'SQL_Latin1_General_CP1_CI_AS'} }
    let(:should_contain_command) { [
        /\-\-\s*UPDATE SECTION.*ALTER\sDATABASE\s\[myTestDb\]\sCOLLATE\sSQL_Latin1_General_CP1_CI_AS/m,
        /\-\-\s*CREATE SECTION.*IF\ NOT\ EXISTS\(SELECT\ name\ FROM\ sys\.databases\ WHERE\ name\ =\ 'myTestDb'\ AND\ collation_name\ =\ 'SQL_Latin1_General_CP1_CI_AS'\)/m,
        /\-\-\s*UPDATE SECTION.*IF\ NOT\ EXISTS\(SELECT\ name\ FROM\ sys\.databases\ WHERE\ name\ =\ 'myTestDb'\ AND\ collation_name\ =\ 'SQL_Latin1_General_CP1_CI_AS'\)/m] }
    let(:should_contain_onlyif) { [
        "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND collation_name = 'SQL_Latin1_General_CP1_CI_AS')"] }
    it_behaves_like 'mssql_tsql command'
    it_behaves_like 'mssql_tsql onlyif'
  end
  describe 'filestream failure' do
    let(:title) { 'myTitle' }
    let(:params) { {
        :db_name => 'myTestDb',
        :instance => 'MSSQLSERVER',
    } }
    it 'should not compile' do
      params.merge!({:filestream_directory_name => 'C:/TestDirectory'})
      expect {
        should contain_mssql_tsql('database-MSSQLSERVER-myTestDb')
      }.to raise_error(Puppet::Error)
    end

  end
  describe 'include filestream_non_transacted_access' do
    let(:additional_params) { {:filestream_non_transacted_access => 'FULL'} }
    let(:should_contain_command) { [/FILESTREAM\s+\(\s+NON_TRANSACTED_ACCESS\s+=\s+FULL/] }
    let(:should_not_contain_command) { [/WITH\s*,\s*FILESTREAM/] }
    it_behaves_like 'mssql_tsql command'
    it_behaves_like 'mssql_tsql without_command'
  end
  describe 'should not contain filestream by default' do
    let(:should_not_contain_command) { [/FILESTREAM/] }
    it_behaves_like 'mssql_tsql without_command'
  end

  describe 'when adding filestream_directory_name' do
    let(:additional_params) { {:filestream_directory_name => 'myDirName'} }
    let(:should_contain_command) { [
        /FILESTREAM\s*\(/,
        /\(\s*DIRECTORY_NAME\s=\s'myDirName'/] }
    let(:should_not_contain_command) { [/NON_TRANSACTED_ACCESS/] }
    it_behaves_like 'mssql_tsql command'
    it_behaves_like 'mssql_tsql without_command'
  end

  describe 'partial parameters' do
    describe 'testing defaults and comma seperation' do
      let(:additional_params) { {:containment => 'PARTIAL'} }
      let(:should_contain_command) {
        [
            /CONTAINMENT\s*=\s*PARTIAL/, #Should be stated after database
            /WITH\s*DB_CHAINING/m, #Should have no comma between, newlines are fine
            /DEFAULT_FULLTEXT_LANGUAGE=\[English\]\s*,/, #Should enclose default language of us_english in brackets
            /TRUSTWORTHY OFF\s*,/,
            /\-\- CREATE.*TWO_DIGIT_YEAR_CUTOFF = 2049.*\-\- UPDATE/m
        ]
      }
      let(:should_not_contain_command) { [
          /NESTED_TRIGGERS/,
          /WITH\s*,\s*DB_CHAINING/m,
          /TRANSFORM_NOISE_WORDS/,
          /FILESTREAM/,
          /TWO_DIGIT_YEAR_CUTOFF = 2049\s*,/
      ] }
      it_behaves_like 'mssql_tsql command'
      it_behaves_like 'mssql_tsql without_command'
    end
    describe 'default_fulltext_language' do
      let(:additional_params) { {:containment => 'PARTIAL', :default_fulltext_language => 'us_english'} }
      let(:should_contain_command) { [/CONTAINMENT\s=\sPARTIAL/, /SET DEFAULT_FULLTEXT_LANGUAGE = \[us_english\]/, /,\s*DEFAULT_FULLTEXT_LANGUAGE=\[us_english\]/m] }
      it_behaves_like 'mssql_tsql command'
    end
    describe 'transform_noise_words ON' do
      let(:additional_params) { {:containment => 'PARTIAL', :transform_noise_words => 'ON'} }
      let(:should_contain_command) { [/CONTAINMENT\s=\sPARTIAL/, /,\s*TRANSFORM_NOISE_WORDS = ON/, /SET TRANSFORM_NOISE_WORDS = ON/, /is_transform_noise_words_on = 1/] }
      it_behaves_like 'mssql_tsql command'
    end
    describe 'transform_noise_words OFF' do
      let(:additional_params) { {:containment => 'PARTIAL', :transform_noise_words => 'OFF'} }
      let(:should_contain_command) { [/CONTAINMENT\s=\sPARTIAL/, /,\s*TRANSFORM_NOISE_WORDS = OFF/, /SET TRANSFORM_NOISE_WORDS = OFF/, /is_transform_noise_words_on = 0/] }
      it_behaves_like 'mssql_tsql command'
    end
    describe 'nested_triggers OFF' do
      let(:additional_params) { {:containment => 'PARTIAL', :nested_triggers => 'OFF'} }
      let(:should_contain_command) { [/CONTAINMENT\s=\sPARTIAL/, /NESTED_TRIGGERS = OFF/, /is_nested_triggers_on = 0/] }
      it_behaves_like 'mssql_tsql command'
    end
    describe 'nested_triggers ON' do
      let(:additional_params) { {:containment => 'PARTIAL', :nested_triggers => 'ON'} }
      let(:should_contain_command) { [/CONTAINMENT\s=\sPARTIAL/, /NESTED_TRIGGERS = ON/, /is_nested_triggers_on = 1/] }
      it_behaves_like 'mssql_tsql command'
    end
    describe 'trustworthy OFF' do
      let(:additional_params) { {:containment => 'PARTIAL', :trustworthy => 'OFF'} }
      let(:should_contain_command) { [/CONTAINMENT\s=\sPARTIAL/, /,\s*TRUSTWORTHY OFF/, /SET TRUSTWORTHY OFF/, /is_trustworthy_on = 0/] }
      it_behaves_like 'mssql_tsql command'
    end
    describe 'trustwothy ON' do
      let(:additional_params) { {:containment => 'PARTIAL', :trustworthy => 'ON'} }
      let(:should_contain_command) { [
          /CONTAINMENT\s=\sPARTIAL/,
          /,\s*TRUSTWORTHY ON/,
          /SET TRUSTWORTHY ON/,
          /is_trustworthy_on = 1/,
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND is_trustworthy_on = 1)"] }
      let(:should_contain_onlyif) { [
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND containment_desc = 'PARTIAL')",
          "IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 'myTestDb' AND is_trustworthy_on = 1)"
      ] }
      it_behaves_like 'mssql_tsql command'
      it_behaves_like 'mssql_tsql onlyif'
    end
  end
end
