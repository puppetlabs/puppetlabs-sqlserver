
Puppet::Type::newtype(:mssql_user) do

  newparam(:username, :namevar => true) do
    desc "The name of a user."
    validate do |value|
      # @todo
    end
  end

  # http://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.logintype.aspx
  # keeping in the same form as we can easily put to String to specify login type during command line
  # Microsoft.SqlServer.Management.Smo.LoginType enum
  newparam(:login_type) do
    newvalues(:AsymmetricKey,:Certificate,:SqlLogin,:WindowsGroup,:WindowsUser)
    #validate if login to ensure domain present if windowsgroup or windowsuser
  end

  # http://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.logincreateoptions(v=sql.110).aspx
  # Microsoft.SqlServer.Management.Smo.LoginCreateOptions enum
  newparam(:login_create_option) do
    defaultto :None
    newvalues(:IsHashed,:MustChange,:None)
  end

  # Use the secure string methods in powershell to provide security around your password
  # ConvertTo-SecureString "P@ssword1" -AsPlainText -Force  | ConvertFrom-SecureString
  newparam(:secure_password) do

  end

end
