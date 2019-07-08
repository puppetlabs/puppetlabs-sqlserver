def stub_source_which_call(source)
  allow(Puppet::Util).to receive(:which).with("#{source}/setup.exe").and_return("#{source}/setup.exe")
end

def stub_powershell_call(subject)
  allow(Puppet::Util).to receive(:which).with('powershell.exe').and_return('powershell.exe')
  allow(Puppet::Provider::Sqlserver).to receive(:run_install_dot_net)
end

def stub_add_features(args, features, additional_switches = [], exit_code = 0)
  stub_modify_features('install', args, features, additional_switches, exit_code)
end

def stub_remove_features(args, features, exit_code = 0)
  stub_modify_features('uninstall', args, features, [], exit_code)
end

def stub_modify_features(action, args, features, additional_switches = [], exit_code = 0)
  cmds = ["#{args[:source]}/setup.exe",
          "/ACTION=#{action}",
          '/Q',
          '/IACCEPTSQLSERVERLICENSETERMS',
          "/FEATURES=#{features.join(',')}",
  ]
  if args.has_key?(:is_svc_account)
    cmds << "/ISSVCACCOUNT=#{args[:is_svc_account]}"
  end
  if args.has_key?(:is_svc_password)
    cmds << "/ISSVCPASSWORD=#{args[:is_svc_password]}"
  end
  additional_switches.each do |switch|
    cmds << switch
  end

  result = Puppet::Util::Execution::ProcessOutput.new('', exit_code)

  allow(Puppet::Util::Execution).to receive(:execute).with(cmds, failonfail: false).and_return(result)
end
