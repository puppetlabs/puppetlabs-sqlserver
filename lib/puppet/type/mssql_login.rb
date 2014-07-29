require 'puppet/property/login'
Puppet::Type::newtype(:mssql_login) do

  newproperty(:login, :namevar => true, :parent => Puppet::Property::MssqlLogin) do
    desc "The loginn you wish to modify."
    validate do |value|
      # @todo write in the validation
    end
  end

  newparam(:instance_name) do
    validate do |value|
      if (value != nil && value.length > 1)
        fail ArgumentError, "instance_name is require"
      end
    end
  end

  newparam(:manage_password) do
    newvalues(:true, :false)
    # default(:true)
  end

  # http://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.logintype.aspx
  # keeping in the same form as we can easily put to String to specify login type during command line
  # Microsoft.SqlServer.Management.Smo.LoginType enum
  newproperty(:login_type) do
    newvalues(:SqlLogin, :WindowsGroup, :WindowsUser)
    #validate if login to ensure domain present if windowsgroup or windowsuser
  end

  # http://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.logincreateoptions(v=sql.110).aspx
  # Microsoft.SqlServer.Management.Smo.LoginCreateOptions enum
  newparam(:login_create_option) do
    defaultto :None
    newvalues(:IsHashed, :MustChange, :None)
  end

  #
  #
  newparam(:password) do

  end

  newparam(:default_database) do

  end

  newparam(:check_expiration) do

  end
  newparam(:check_policy) do

  end

end
