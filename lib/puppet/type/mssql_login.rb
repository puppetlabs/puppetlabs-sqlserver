require 'puppet/property/login'

# Based on http://msdn.microsoft.com/en-us/library/ms189751(v=sql.110).aspx
Puppet::Type::newtype(:mssql_login) do
  ensurable

  newparam(:name, :namevar => true, :parent => Puppet::Property::MssqlLogin) do
    desc "The loginn you wish to modify."

  end

  newparam(:instance_name) do
    desc 'Instance to run against'
    defaultto('DEFAULT')
    munge do |value|
      if value == 'MSSQLSERVER'
        value = 'DEFAULT'
      end
    end
  end

  newparam(:admin_user) do
    desc 'User has SELECT, CREATE, ALTER access for users'

  end

  newparam(:admin_pass) do
    desc ''

  end

  newparam(:manage_password) do
    newvalues(:true, :false)
    defaultto(:false)
  end

  # http://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.logintype.aspx
  # keeping in the same form as we can easily put to String to specify login type during command line
  # Microsoft.SqlServer.Management.Smo.LoginType enum
  newproperty(:login_type) do
    newvalues(:SqlLogin, :WindowsGroup, :WindowsUser)
    defaultto :SqlLogin
    #validate if login to ensure domain present if windowsgroup or windowsuser
  end

  # http://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.logincreateoptions(v=sql.110).aspx
  # Microsoft.SqlServer.Management.Smo.LoginCreateOptions enum
  newparam(:login_create_option) do
    newvalues(:IsHashed, :MustChange, :None)
    defaultto :None
  end

  #
  #
  #
  newparam(:password) do
    validate do |value|
      if value == nil
        return
      end
      if (value.length < 8 || value.length > 128) && self[:login_type] == :SqlLogin
        fail ArgumentError, 'Password must be between 8 and 128 characters'
      end
      if value.match(/\'/)
        fail ArgumentError, 'Password can not contain quotes'
      end
    end
  end

  newproperty(:default_database) do
    defaultto('master')
  end

  newproperty(:default_language) do
    defaultto('us_english')
  end
  newproperty(:disabled) do
    newvalues(:true, :false)
    defaultto(:false)
  end


  newproperty(:check_expiration) do
    newvalues(:ON, :on, :OFF, :off)
    defaultto :ON
    munge do |value|
      value.upcase
    end
  end

  newproperty(:check_policy) do
    newvalues(:ON, :OFF, :on, :off)
    defaultto :ON
    munge do |value|
      value.upcase
    end
  end

  autorequire(:mssql_instance) do
    req = []

    # Start at our parent, to avoid autorequiring ourself
    parents = path.parent.enum_for(:ascend)
    if found = parents.find { |p| catalog.resource(:mssql_instance, self[:instance]) }
      req << found.to_s
    end
    # if the resource is a link, make sure the target is created first
    req << self[:target] if self[:target]
    req
  end
end
