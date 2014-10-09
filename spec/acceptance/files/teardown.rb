# This method is intended to assist in the removal of a ms-sql installation
def uninstall_instance(instance_name)

  pp = <<-ESO
  mssql_instance{ '#{instance_name}':
    ensure => absent,
  }->
  reboot{ 'now':
  }
  ESO

  agents.each do |a|
    apply_manifest(pp) if (fact_on(a, 'osfamily') == 'windows')
  end

end
