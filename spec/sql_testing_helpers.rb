def mount_iso(host, opts = {})
  # This method mounts the ISO on a given host
  qa_iso_resource_root = opts[:qa_iso_resource_root]
  sqlserver_iso = opts[:sqlserver_iso]
  sqlserver_version = opts[:sqlserver_version]
  pp = <<-MANIFEST
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
  apply_manifest_on(host, pp)
end

def install_sqlserver(host, opts = {})
  # this method installs SQl server on a given host
  features = opts[:features].map{ |x| "'#{x}'"}.join(', ')
  pp = <<-MANIFEST
    sqlserver_instance{'MSSQLSERVER':
      source => 'H:',
      features => [ #{features} ],
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
    apply_manifest_on(host, pp)
end

def run_sql_query(host, opts = {}, &block)
  # runs an arbitrary SQL command
  opts[:expected_row_count] ||= 1
  query = opts[:query]
  sql_admin_pass = opts[:sql_admin_pass] ||= SQL_ADMIN_PASS
  sql_admin_user = opts[:sql_admin_user] ||= SQL_ADMIN_USER
  environment_path = '/cygdrive/c/Program Files/Microsoft SQL Server/Client SDK/ODBC/110/Tools/Binn:/cygdrive/c/Program Files/Microsoft SQL Server/110/Tools/Binn'
  tmpfile = host.tmpfile('should_contain_query.sql')
  create_remote_file(host, tmpfile, query + "\n")
  tmpfile.gsub!("/", "\\")
  sqlcmd_query = <<-sql_query
  sqlcmd.exe -U #{sql_admin_user} -P #{sql_admin_pass} -h-1 -W -s "|" -i \"#{tmpfile}\"
  sql_query
  on(host, sqlcmd_query, :environment => {"PATH" => environment_path}) do |result|

    unless opts[:expected_row_count] == 0
      # match an expeted row count
      match = /(\d*) rows affected/.match(result.stdout)
      raise 'Could not match number of rows for SQL query' unless match
      rows_observed = match[1]
      error_message = "Expected #{opts[:expected_row_count]} rows but observed #{rows_observed}"
      raise error_message unless opts[:expected_row_count] == rows_observed.to_i
    end
    case block.arity
    when 0
      yield self
    else
      yield result
    end
  end
end

def base_install(sql_version)
  case sql_version.to_i
  when 2012
    iso_opts = {
      :qa_iso_resource_root   => QA_RESOURCE_ROOT,
      :sqlserver_iso          => SQL_2012_ISO,
      :sqlserver_version      => '2012',
    }
  when 2014
    iso_opts = {
      :qa_iso_resource_root   => QA_RESOURCE_ROOT,
      :sqlserver_iso          => SQL_2014_ISO,
      :sqlserver_version      => '2014',
    }
  end
  host = find_only_one('sql_host')
  # Mount the ISO on the agent
  mount_iso(host, iso_opts)
  # Install Microsoft SQL on the agent before running any tests
  install_sqlserver(host, {:features => ['SQL']})
end

def validate_sql_install(host, opts = {}, &block)
  bootstrap_dir, setup_dir = get_install_paths(opts[:version])

  # NOTE: executing a fully qualified setup.exe quoted this way fails
  # but that can be circumvented by first changing directories
  cmd = "cd \\\"#{setup_dir}\\\" && setup.exe /Action=RunDiscovery /q"
  on(host, "cmd.exe /c \"#{cmd}\"")

  cmd = "type \\\"#{bootstrap_dir}\\Log\\Summary.txt\\\""
  result = on(host, "cmd.exe /c \"#{cmd}\"")
  if block_given?
    case block.arity
    when 0
      yield self
    else
      yield result
    end
  end
end

def remove_sql_features(host, opts = {})
  bootstrap_dir, setup_dir = get_install_paths(opts[:version])
  cmd = "cd \\\"#{setup_dir}\\\" && setup.exe /Action=uninstall /Q /IACCEPTSQLSERVERLICENSETERMS /FEATURES=#{opts[:features].join(',')}"
  on(host, "cmd.exe /c \"#{cmd}\"", {:acceptable_exit_codes => [0, 1, 2]})
end

def get_install_paths(version)
  vers = { '2012' => '110', '2014' => '120' }

  raise 'Valid version must be specified' if ! vers.keys.include?(version)

  dir = "%ProgramFiles%\\Microsoft SQL Server\\#{vers[version]}\\Setup Bootstrap"
  [dir, "#{dir}\\SQLServer#{version}"]
end

def install_ca_certs(host)
  geotrust_global_ca = <<-EOM
-----BEGIN CERTIFICATE-----
MIIDVDCCAjygAwIBAgIDAjRWMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNVBAYTAlVT
MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i
YWwgQ0EwHhcNMDIwNTIxMDQwMDAwWhcNMjIwNTIxMDQwMDAwWjBCMQswCQYDVQQG
EwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEbMBkGA1UEAxMSR2VvVHJ1c3Qg
R2xvYmFsIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2swYYzD9
9BcjGlZ+W988bDjkcbd4kdS8odhM+KhDtgPpTSEHCIjaWC9mOSm9BXiLnTjoBbdq
fnGk5sRgprDvgOSJKA+eJdbtg/OtppHHmMlCGDUUna2YRpIuT8rxh0PBFpVXLVDv
iS2Aelet8u5fa9IAjbkU+BQVNdnARqN7csiRv8lVK83Qlz6cJmTM386DGXHKTubU
1XupGc1V3sjs0l44U+VcT4wt/lAjNvxm5suOpDkZALeVAjmRCw7+OC7RHQWa9k0+
bw8HHa8sHo9gOeL6NlMTOdReJivbPagUvTLrGAMoUgRx5aszPeE4uwc2hGKceeoW
MPRfwCvocWvk+QIDAQABo1MwUTAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTA
ephojYn7qwVkDBF9qn1luMrMTjAfBgNVHSMEGDAWgBTAephojYn7qwVkDBF9qn1l
uMrMTjANBgkqhkiG9w0BAQUFAAOCAQEANeMpauUvXVSOKVCUn5kaFOSPeCpilKIn
Z57QzxpeR+nBsqTP3UEaBU6bS+5Kb1VSsyShNwrrZHYqLizz/Tt1kL/6cdjHPTfS
tQWVYrmm3ok9Nns4d0iXrKYgjy6myQzCsplFAMfOEVEiIuCl6rYVSAlk6l5PdPcF
PseKUgzbFbS9bZvlxrFUaKnjaZC2mqUPuLk/IH2uSrW4nOQdtqvmlKXBx4Ot2/Un
hw4EbNX/3aBd7YdStysVAq45pmp06drE57xNNB6pXE0zX5IJL4hmXXeXxx12E6nV
5fEWCRE11azbJHFwLJhWC9kXtNHjUStedejV0NxPNO3CBWaAocvmMw==
-----END CERTIFICATE-----
EOM

  usertrust_network_ca = <<-EOM
-----BEGIN CERTIFICATE-----
MIIEdDCCA1ygAwIBAgIQRL4Mi1AAJLQR0zYq/mUK/TANBgkqhkiG9w0BAQUFADCB
lzELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0IExha2Ug
Q2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYDVQQLExho
dHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHzAdBgNVBAMTFlVUTi1VU0VSRmlyc3Qt
SGFyZHdhcmUwHhcNOTkwNzA5MTgxMDQyWhcNMTkwNzA5MTgxOTIyWjCBlzELMAkG
A1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0IExha2UgQ2l0eTEe
MBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYDVQQLExhodHRwOi8v
d3d3LnVzZXJ0cnVzdC5jb20xHzAdBgNVBAMTFlVUTi1VU0VSRmlyc3QtSGFyZHdh
cmUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx98M4P7Sof885glFn
0G2f0v9Y8+efK+wNiVSZuTiZFvfgIXlIwrthdBKWHTxqctU8EGc6Oe0rE81m65UJ
M6Rsl7HoxuzBdXmcRl6Nq9Bq/bkqVRcQVLMZ8Jr28bFdtqdt++BxF2uiiPsA3/4a
MXcMmgF6sTLjKwEHOG7DpV4jvEWbe1DByTCP2+UretNb+zNAHqDVmBe8i4fDidNd
oI6yqqr2jmmIBsX6iSHzCJ1pLgkzmykNRg+MzEk0sGlRvfkGzWitZky8PqxhvQqI
DsjfPe58BEydCl5rkdbux+0ojatNh4lz0G6k0B4WixThdkQDf2Os5M1JnMWS9Ksy
oUhbAgMBAAGjgbkwgbYwCwYDVR0PBAQDAgHGMA8GA1UdEwEB/wQFMAMBAf8wHQYD
VR0OBBYEFKFyXyYbKJhDlV0HN9WFlp1L0sNFMEQGA1UdHwQ9MDswOaA3oDWGM2h0
dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9VVE4tVVNFUkZpcnN0LUhhcmR3YXJlLmNy
bDAxBgNVHSUEKjAoBggrBgEFBQcDAQYIKwYBBQUHAwUGCCsGAQUFBwMGBggrBgEF
BQcDBzANBgkqhkiG9w0BAQUFAAOCAQEARxkP3nTGmZev/K0oXnWO6y1n7k57K9cM
//bey1WiCuFMVGWTYGufEpytXoMs61quwOQt9ABjHbjAbPLPSbtNk28Gpgoiskli
CE7/yMgUsogWXecB5BKV5UU0s4tpvc+0hY91UZ59Ojg6FEgSxvunOxqNDYJAB+gE
CJChicsZUN/KHAG8HQQZexB2lzvukJDKxA4fFm517zP4029bHpbj4HR3dHuKom4t
3XbWOTCC8KucUvIqx69JXn7HaOWCgchqJ/kniCrVWFCVH/A7HFe7fRQ5YiuayZSS
KqMiDP+JJn1fIytH1xUdqWqeUQ0qUZ6B+dQ7XnASfxAynB67nfhmqA==
-----END CERTIFICATE-----
EOM

  equifax_ca = <<-EOM
-----BEGIN CERTIFICATE-----
MIIDIDCCAomgAwIBAgIENd70zzANBgkqhkiG9w0BAQUFADBOMQswCQYDVQQGEwJV
UzEQMA4GA1UEChMHRXF1aWZheDEtMCsGA1UECxMkRXF1aWZheCBTZWN1cmUgQ2Vy
dGlmaWNhdGUgQXV0aG9yaXR5MB4XDTk4MDgyMjE2NDE1MVoXDTE4MDgyMjE2NDE1
MVowTjELMAkGA1UEBhMCVVMxEDAOBgNVBAoTB0VxdWlmYXgxLTArBgNVBAsTJEVx
dWlmYXggU2VjdXJlIENlcnRpZmljYXRlIEF1dGhvcml0eTCBnzANBgkqhkiG9w0B
AQEFAAOBjQAwgYkCgYEAwV2xWGcIYu6gmi0fCG2RFGiYCh7+2gRvE4RiIcPRfM6f
BeC4AfBONOziipUEZKzxa1NfBbPLZ4C/QgKO/t0BCezhABRP/PvwDN1Dulsr4R+A
cJkVV5MW8Q+XarfCaCMczE1ZMKxRHjuvK9buY0V7xdlfUNLjUA86iOe/FP3gx7kC
AwEAAaOCAQkwggEFMHAGA1UdHwRpMGcwZaBjoGGkXzBdMQswCQYDVQQGEwJVUzEQ
MA4GA1UEChMHRXF1aWZheDEtMCsGA1UECxMkRXF1aWZheCBTZWN1cmUgQ2VydGlm
aWNhdGUgQXV0aG9yaXR5MQ0wCwYDVQQDEwRDUkwxMBoGA1UdEAQTMBGBDzIwMTgw
ODIyMTY0MTUxWjALBgNVHQ8EBAMCAQYwHwYDVR0jBBgwFoAUSOZo+SvSspXXR9gj
IBBPM5iQn9QwHQYDVR0OBBYEFEjmaPkr0rKV10fYIyAQTzOYkJ/UMAwGA1UdEwQF
MAMBAf8wGgYJKoZIhvZ9B0EABA0wCxsFVjMuMGMDAgbAMA0GCSqGSIb3DQEBBQUA
A4GBAFjOKer89961zgK5F7WF0bnj4JXMJTENAKaSbn+2kmOeUJXRmm/kEd5jhW6Y
7qj/WsjTVbJmcVfewCHrPSqnI0kBBIZCe/zuf6IWUrVnZ9NA2zsmWLIodz2uFHdh
1voqZiegDfqnc1zqcPGUIWVEX/r87yloqaKHee9570+sB3c4
-----END CERTIFICATE-----
EOM


  # Installing Geotrust CA cert
  create_remote_file(host, "geotrustglobal.pem", geotrust_global_ca)
  on host, "chmod 644 geotrustglobal.pem"
  on host, "cmd /c certutil -v -addstore Root `cygpath -w geotrustglobal.pem`"

  # Installing Usertrust Network CA cert
  create_remote_file(host, "usertrust-network.pem", usertrust_network_ca)
  on host, "chmod 644 usertrust-network.pem"
  on host, "cmd /c certutil -v -addstore Root `cygpath -w usertrust-network.pem`"

  # Installing Equifax CA cert
  create_remote_file(host, "equifax.pem", equifax_ca)
  on host, "chmod 644 equifax.pem"
  on host, "cmd /c certutil -v -addstore Root `cygpath -w equifax.pem`"
end
