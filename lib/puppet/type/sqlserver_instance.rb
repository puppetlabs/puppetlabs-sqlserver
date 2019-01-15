require File.expand_path(File.join(File.dirname(__FILE__), '..', 'property/sqlserver_login'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x/sqlserver/server_helper'))

Puppet::Type::newtype(:sqlserver_instance) do

  ensurable

  newparam(:name, :namevar => true) do
    munge do |value|
      value.upcase
    end
  end

  newparam(:source) do

  end

  newparam(:windows_feature_source) do
    desc 'Specify the location of the Windows Feature source files.  This may be needed to install the .Net Framework.
          See https://support.microsoft.com/en-us/kb/2734782 for more information.'
  end

  newparam(:pid) do
    desc 'Specify the SQL Server product key to configure which edition you would like to use.'

  end

  newproperty(:features, :array_matching => :all) do
    desc 'Specifies features to install, uninstall, or upgrade. The list of top-level features include
          SQLEngine, Replication, FullText, DQ AS, and RS.'
    newvalues(:SQL, :SQLEngine, :Replication, :FullText, :DQ, :AS, :RS, :POLYBASE, :ADVANCEDANALYTICS)
    munge do |value|
      if PuppetX::Sqlserver::ServerHelper.is_super_feature(value)
        Puppet.deprecation_warning("Using #{value} is deprecated for features in sql_instance resources")
        PuppetX::Sqlserver::ServerHelper.get_sub_features(value).collect { |v| v.to_s }
      else
        value
      end
    end
  end

  newparam(:sa_pwd) do
    desc 'Required when :security_mode => "SQL"'

  end

  newparam(:sql_svc_account, :parent => Puppet::Property::SqlserverLogin) do
    desc 'Account for SQL Server service: Domain\User or system account.'
    # Default to "NT Service\SQLAGENT$#{instance_name}"

  end

  newparam(:sql_svc_password) do
    desc 'A SQL Server service password is required only for a domain account.'

  end

  newparam(:sql_sysadmin_accounts, :array_matching => :all) do
    desc 'Windows account(s) to provision as SQL Server system administrators.'

  end

  newparam(:agt_svc_account, :parent => Puppet::Property::SqlserverLogin) do
    desc 'Either domain user name or system account'

  end

  newparam(:agt_svc_password) do
    desc 'Password for domain user name. Not required for system account'

  end

  newparam(:as_svc_account, :parent => Puppet::Property::SqlserverLogin) do
    desc 'The account used by the Analysis Services service.'

  end

  newparam(:as_svc_password) do
    desc 'The password for the Analysis Services service account.'

  end

  newparam(:as_sysadmin_accounts, :array_matching => :all) do
    desc 'Specifies the list of administrator accounts to provision.'
  end

  newparam(:rs_svc_account, :parent => Puppet::Property::SqlserverLogin) do
    desc 'Specify the service account of the report server. This value is required.
          If you omit this value, Setup will use the default built-in account for
          the current operating system (either NetworkService or LocalSystem).
          If you specify a domain user account, the domain must be under 254 characters
          and the user name must be under 20 characters. The account name cannot contain the
          following characters: " / \ [ ] : ; | = , + * ? < > '
    validate do |value|
      value.kind_of? String
      matches = value.scan(/(\/|\\|\[|\]|\:|\;|\||\=|\,|\+|\*|\?|\<|\>)/)
      if !matches.empty?
        fail("rs_svc_account can not contain any of the special characters, / \\ [ ] : ; | = , + * ? < >, your entry contained #{matches}")
      end
    end
  end

  newparam(:rs_svc_password) do
    desc 'Specify a strong password for the account. A strong password is at least 8 characters and
          includes a combination of upper and lower case alphanumeric characters and at least one symbol
          character. Avoid spelling an actual word or name that might be listed in a dictionary.'
    validate do |value|

    end
  end

  newparam(:polybase_svc_account, :parent => Puppet::Property::SqlserverLogin) do
    desc 'The account used by the Polybase Engine service. Only applicable for SQL Server 2016+.'

  end

  newparam(:polybase_svc_password) do
    desc 'The password for the Polybase Engine service account. Only applicable for SQL Server 2016+.'

  end

  newparam(:security_mode) do
    desc 'Specifies the security mode for SQL Server.
          If this parameter is not supplied, then Windows-only authentication mode is supported.
          Supported value: SQL'
    newvalues('SQL')
  end

  newparam(:install_switches) do
    desc 'A hash of switches you want to pass to the installer'
    validate do |value|
      fail ArguemntError, 'install_switch must be in the form of a Hash' unless value.is_a?(Hash)
    end
  end


  def validate
    if set?(:agt_svc_account)
      validate_user_password_required(:agt_svc_account, :agt_svc_password)
    end
    if set?(:features)
      self[:features] = self[:features].flatten.sort.uniq
    end


    # RS Must have Strong Password
    if set?(:rs_svc_password) && self[:features].include?("RS")
      is_strong_password?(:rs_svc_password)
    end
    if self[:security_mode] == 'SQL'
      is_strong_password?(:sa_pwd)
    end

  end

  def set?(key)
    !self[key].nil? && !self[key].empty?
  end

  def validate_user_password_required(account, pass)
    if !(set?(account))
      fail("User #{account} is required")
    end
    if is_domain_or_local_user?(self[account]) && self[pass].nil?
      fail("#{pass} required when using domain account")
    end
  end

  def is_domain_or_local_user?(user)
    PuppetX::Sqlserver::ServerHelper.is_domain_or_local_user?(user, Facter.value(:hostname))
  end

  def is_strong_password?(key)
    password = self[key]
    if !password
      return
    end
    message_start = "Password for #{key} is not strong"
    failures = []
    if password.length < 8
      failures << "must be at least 8 characters long"
    end
    if !(password.match(/[a-z]/))
      failures << "must contain lowercase letters"
    end
    if !(password.match(/[A-Z]/))
      failures << "must contain uppercase letters"
    end
    if !(password.match(/\d/))
      failures << 'must contain numbers'
    end
    if !(password.match(//))
      failures << 'must contain a special character'
    end
    if failures.count > 0
      fail("#{message_start}:\n#{failures.join("\n")}")
    end
    true
  end
end
