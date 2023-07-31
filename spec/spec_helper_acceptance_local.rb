# frozen_string_literal: true

require 'puppet_litmus'
require 'singleton'

class Helper
  include Singleton
  include PuppetLitmus
end

WIN_ISO_ROOT = 'https://artifactory.delivery.puppetlabs.net/artifactory/generic__iso/iso/windows'
WIN_2019_ISO = 'en_windows_server_2019_updated_july_2020_x64_dvd_94453821.iso'
QA_RESOURCE_ROOT = 'https://artifactory.delivery.puppetlabs.net/artifactory/generic__iso/iso/SQLServer'
SQL_2022_ISO = 'SQLServer2022-x64-ENU-Dev.iso'
SQL_2019_ISO = 'SQLServer2019CTP2.4-x64-ENU.iso'
SQL_2017_ISO = 'SQLServer2017-x64-ENU.iso'
SQL_2016_ISO = 'en_sql_server_2016_enterprise_with_service_pack_1_x64_dvd_9542382.iso'
SQL_2014_ISO = 'SQLServer2014SP3-FullSlipstream-x64-ENU.iso'
SQL_2012_ISO = 'SQLServer2012SP1-FullSlipstream-ENU-x64.iso'
SQL_ADMIN_USER = 'sa'
SQL_ADMIN_PASS = 'Pupp3t1@'
USER = Helper.instance.run_shell('$env:UserName').stdout.chomp
