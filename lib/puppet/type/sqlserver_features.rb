require 'puppet/property/login'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x/mssql/server_helper'))

Puppet::Type::newtype(:sqlserver_features) do
  ensurable


  newparam(:name, :namevar => true) do
    #Due to our prefetch and unaware of what name the user will provide we munge the value to meet our expecations.
    munge do |value|
      'Generic Features'
    end
  end

  newparam(:source)

  newparam(:pid) do
    desc 'Specify the SQL Server product key to configure which edition you would like to use.'

  end

  newparam(:is_svc_account, :parent => Puppet::Property::MssqlLogin) do
    desc 'Either domain user name or system account. Defaults to "NT AUTHORITY\NETWORK SERVICE"'

  end

  newparam(:is_svc_password) do
    desc 'Password for domain user.'

  end

  newproperty(:features, :array_matching => :all) do
    desc 'Specifies features to install, uninstall, or upgrade. The list of top-level features include
         Tools, BC, Conn, SSMS, ADV_SSMS, SDK, IS and MDS. The Tools feature will install Management
          Tools, Books online components, SQL Server Data Tools, and other shared components.'
    newvalues(:Tools, :BC, :Conn, :SSMS, :ADV_SSMS, :SDK, :IS, :MDS)
    munge do |value|
      if PuppetX::Mssql::ServerHelper.is_super_feature(value)
        PuppetX::Mssql::ServerHelper.get_sub_features(value).collect { |v| v.to_s }
      else
        value
      end
    end
  end

  def validate
    if set?(:features)
      self[:features] = self[:features].flatten.sort.uniq
    end
    # IS_SVC_ACCOUNT validation

    if set?(:features) && self[:features].include?("IS")
      if set?(:is_svc_account) || set?(:is_svc_password)
        validate_user_password_required(:is_svc_account, :is_svc_password)
      end
    end
  end

  def is_domain_or_local_user?(user)
    PuppetX::Mssql::ServerHelper.is_domain_or_local_user?(user, Facter.value(:hostname))
  end

  def validate_user_password_required(account, pass)
    if !(set?(account))
      fail("User #{account} is required")
    end
    if is_domain_or_local_user?(self[account]) && !set?(pass)
      fail("#{pass} required when using domain account")
    end
  end

  def set?(key)
    !self[key].nil? && !self[key].empty?
  end
end
