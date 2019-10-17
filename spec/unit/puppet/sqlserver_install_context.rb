def get_basic_args
  {
    source: 'C:\myinstallexecs',
    pid: 'areallyCrazyLongPid',
    features: ['SQL', 'AS', 'RS', 'POLYBASE'],
    name: 'MYSQLSERVER_HOST',
    agt_svc_account: 'nexus\travis',
    agt_svc_password: 'P@ssword1',
    as_svc_account: 'analysisAccount',
    as_svc_password: 'CrazySimpleP@ssword',
    rs_svc_account: 'reportUserAccount', # always local user
    rs_svc_password: 'reportP@ssword1',
    polybase_svc_account: 'nexus\polyuser',
    polybase_svc_password: 'P@ssword1',
    sql_svc_account: 'NT Service\MSSQLSERVER',
    sql_sysadmin_accounts: ['localAdminAccount', 'nexus\domainUser'],
  }
end
