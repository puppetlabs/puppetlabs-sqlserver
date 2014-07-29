require 'puppet/property/login'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x/mssql/helper'))

Puppet::Type::newtype(:mssql_install) do

  newparam(:name) do
    isnamevar
  end
  newparam(:source) do

  end

  newproperty(:pid) do
    desc 'Specify the SQL Server product key to configure which edition you would like to use.'

  end

  newproperty(:features, :array_matching => :all) do
    desc 'Specifies features to install, uninstall, or upgrade. The list of top-level features include
          SQL, AS, RS, IS, MDS, and Tools. The SQL feature will install the Database Engine, Replication,
          Full-Text, and Data Quality Services (DQS) server. The Tools feature will install Management
          Tools, Books online components, SQL Server Data Tools, and other shared components.'
  end

  newproperty(:instance_name) do
    desc 'Specify a default or named instance. MSSQLSERVER  is the default instance for non-Express
          editions and SQLExpress for Express editions. This parameter is required when installing
          the SQL Server Database Engine (SQL), Analysis Services (AS), or Reporting Services (RS).'
    defaultto('MSSQLSERVER')
  end

  newproperty(:sql_svc_account, :parent => Puppet::Property::MssqlLogin) do
    desc 'Account for SQL Server service: Domain\User or system account.'

  end

  newproperty(:sql_svc_password) do
    desc 'A SQL Server service password is required only for a domain account.'
    # validate do |value|
    #   if !mssql_is_domain_user(self[:sql_svc_account]) && value.empty?
    #     fail('sql_svc_password required when not using domain account')
    #   end
    # end
  end

  newproperty(:sql_sysadmin_accounts, :array_matching => :all) do
    desc 'Windows account(s) to provision as SQL Server system administrators.'

  end

  newproperty(:agt_svc_account, :parent => Puppet::Property::MssqlLogin) do
    desc 'Either domain user name or system account'

  end

  newproperty(:agt_svc_password) do
    desc 'Password for domain user name. Not required for system account'

  end

  newproperty(:as_svc_account, :parent => Puppet::Property::MssqlLogin) do
    desc 'The account used by the Analysis Services service.'

  end
  newproperty(:as_svc_password) do
    desc 'The password for the Analysis Services service account.'

  end
  newproperty(:rs_svc_account, :parent => Puppet::Property::MssqlLogin) do
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
  newproperty(:rs_svc_password) do
    desc 'Specify a strong password for the account. A strong password is at least 8 characters and
          includes a combination of upper and lower case alphanumeric characters and at least one symbol
          character. Avoid spelling an actual word or name that might be listed in a dictionary.'
    validate do |value|

    end
  end


  newproperty(:is_svc_account, :parent => Puppet::Property::MssqlLogin) do
    desc 'Either domain user name or system account.'

  end
  newproperty(:is_svc_password) do
    desc 'Password for domain user.'

  end

  newproperty(:as_sysadmin_accounts, :array_matching => :all) do
    desc 'Specifies the list of administrator accounts to provision.'
  end

  def validate
    # AGT_SVC_ACCOUNT Validation
    validate_user_password_required(:agt_svc_account, :agt_svc_password)
    # IS_SVC_ACCOUNT validation
    validate_user_password_required(:is_svc_account, :is_svc_password)
    #
    if self[:features].include? 'RS'
      is_strong_password?(:rs_svc_password)
    end
  end


  def validate_user_password_required(account, pass)
    if is_domain_user?(self[account]) && self[pass].nil?
      fail("#{pass} required when using domain account")
    end
  end

  def is_domain_user?(user)
    PuppetX::Mssql::Helper.is_domain_user?(user, Facter.value(:hostname))
  end

  def is_strong_password?(key)
    password = self[key]
    if !password
      return
    end
    message_start = "Password for #{key} is not strong"
    failures = []
    if password.length < 8
      failures << 'must be at least 8 characters long'
    end
    if !(password.match(/[a-z]/))
      failures << 'must contain lowercase letters'
    end
    if !(password.match(/[A-Z]/))
      failures << 'must contain uppercase letters'
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
  end

end
