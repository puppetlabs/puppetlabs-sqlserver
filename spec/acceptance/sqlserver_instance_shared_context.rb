require 'spec_helper_acceptance'

QA_RESOURE_ROOT = "http://int-resources.ops.puppetlabs.net/QA_resources/microsoft_sql/iso/"
SQL_2014_ISO = "SQLServer2014-x64-ENU.iso"
SQL_2012_ISO = "SQLServer2012SP1-FullSlipstream-ENU-x64.iso"

RSpec.shared_context 'sqlserver_instance_context' do
  let(:sqlserver_version) { '2014' }
  let(:sqlserver_iso) { SQL_2014_ISO }
  let(:qa_iso_resource_root) { QA_RESOURE_ROOT }
  let(:packages_installed) { ["Database Engine Services", "Data Quality Service", "Full text search", "Database Engine Shared"] }
  let(:packages_uninstalled) { [] }
  let(:services_installed) { ["SQL Server (MSSQLSERVER)"] }
  let(:services_uninstalled) { [] }
  let(:beaker_host) { nil }
  let(:install_manifest) {
    <<-MANIFEST
    sqlserver_instance{'MSSQLSERVER':
      source => 'H:',
      features => ['SQL'],
      security_mode => 'SQL',
      sa_pwd => 'Pupp3t1@',
      sql_sysadmin_accounts => ['Administrator'],
      install_switches => {
        'TCPENABLED'          => 1,
        'SQLBACKUPDIR'        => 'C:\\MSSQLSERVER\\backupdir',
        'SQLTEMPDBDIR'        => 'C:\\MSSQLSERVER\\tempdbdir',
        'INSTALLSQLDATADIR'   => 'C:\\MSSQLSERVER\\datadir',
        'INSTANCEDIR'         => 'C:\\Program Files\\Microsoft SQL Server',
        'INSTALLSHAREDDIR'    => 'C:\\Program Files\\Microsoft SQL Server',
        'INSTALLSHAREDWOWDIR' => 'C:\\Program Files (x86)\\Microsoft SQL Server',
      }
    }
    MANIFEST
  }
  shared_examples 'server_prefetch' do
    it {
      manifest_pre = <<-MANIFEST
  $p_src  = '#{qa_iso_resource_root}/#{sqlserver_iso}'
  $source = 'C:\\#{sqlserver_iso}'
  pget{"Download #{sqlserver_version} Iso":
    source  => $p_src,
    target  => 'C:',
    timeout => 150000,
  }
  mount_iso{$source:
	  require      => Pget['Download #{sqlserver_version} Iso'],
	  drive_letter => 'H',
  }
      MANIFEST
      apply_manifest_on(beaker_host, manifest_pre)
    }
  end

  shared_examples 'install sqlserver' do
    it { apply_manifest_on(beaker_host, install_manifest) }
  end

  shared_examples 'services installed' do |services_installed = ["SQL Server (MSSQLSERVER)"]|
    services_installed.each do |service|
      describe service(service) do
        it { should be_installed }
        it { should be_enabled }
      end
    end
  end

  shared_examples 'packages installed' do |packages_installed|
    packages_installed.each do |package|
      describe package(package) do
        it { should be_installed }
      end
    end
  end

end
