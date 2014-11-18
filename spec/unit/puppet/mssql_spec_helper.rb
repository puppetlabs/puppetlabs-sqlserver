def stub_source_which_call(source)
  Puppet::Util.stubs(:which).with("#{source}/setup.exe").returns("#{source}/setup.exe")
end

def stub_powershell_call(subject)
  Puppet::Util.stubs(:which).with('powershell.exe').returns('powershell.exe')
  subject.expects(:powershell)
end

def stub_add_features(source, features)
  stub_modify_features('install', source, features)
end

def stub_remove_features(source, features)
  stub_modify_features('uninstall', source, features)
end

def stub_modify_features(action, source, features)
  Puppet::Util::Execution.stubs(:execute).with(
      ["#{source}/setup.exe",
       "/ACTION=#{action}",
       '/Q',
       '/IACCEPTSQLSERVERLICENSETERMS',
       "/FEATURES=#{features.join(',')}",
      ]).returns(0)
end
