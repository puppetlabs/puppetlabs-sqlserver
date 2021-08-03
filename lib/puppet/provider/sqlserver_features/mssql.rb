# frozen_string_literal: true

require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x/sqlserver/server_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x/sqlserver/features'))

FEATURE_RESERVED_SWITCHES =
  ['AGTSVCACCOUNT', 'AGTSVCPASSWORD', 'ASSVCACCOUNT', 'AGTSVCPASSWORD', 'PID', 'RSSVCACCOUNT', 'RSSVCPASSWORD', 'SAPWD', 'SECURITYMODE', 'SQLSYSADMINACCOUNTS', 'FEATURES'].freeze

Puppet::Type.type(:sqlserver_features).provide(:mssql, parent: Puppet::Provider::Sqlserver) do
  desc 'SQLServer Features provider'

  def self.instances
    instances = []
    result = Facter.value(:sqlserver_features)
    debug "Parsing result #{result}"

    # Due to MODULES-5060 we can only output one feature set.  If we output
    # multiple then it is not possible to install or uninstall due to multiple
    # resources with the same name.  Also due to the SQL Native Client not
    # being unique across SQL Server versions (e.g. SQL 2016 installs Native Client
    # with a version that matches for SQL 2012) the features need to be collated
    # across all versions and then aggregated into a single resource
    featurelist = []
    ALL_SQL_VERSIONS.each do |sql_version|
      next if result[sql_version].empty?
      featurelist += result[sql_version]
    end

    unless featurelist.count.zero?
      instance_props = { name: 'Generic Features',
                         ensure: :present,
                         features: featurelist.uniq.sort }
      debug "Parsed features = #{instance_props[:features]}"
      instances = [new(instance_props)]
    end

    instances
  end

  def self.prefetch(resources)
    features = instances
    resources.each_key do |name|
      if (provider = features.find { |feature| feature.name == name })
        resources[name].provider = provider
      end
    end
  end

  def remove_features(features)
    modify_features('uninstall', features)
  end

  def add_features(features)
    modify_features('install', features)
  end

  def modify_features(action, features)
    return unless not_nil_and_not_empty? features
    debug "#{action.capitalize}ing features '#{features.join(',')}'"
    cmd_args = ["#{@resource[:source]}/setup.exe",
                "/ACTION=#{action}",
                '/Q',
                '/IACCEPTSQLSERVERLICENSETERMS',
                "/FEATURES=#{features.join(',')}"]
    if action == 'install'
      if not_nil_and_not_empty?(@resource[:is_svc_account])
        cmd_args << "/ISSVCACCOUNT=#{@resource[:is_svc_account]}"
      end
      if not_nil_and_not_empty?(@resource[:is_svc_password])
        cmd_args << "/ISSVCPASSWORD=#{@resource[:is_svc_password]}"
      end
      if not_nil_and_not_empty?(@resource[:pid])
        cmd_args << "/PID=#{@resource[:pid]}"
      end
    end
    begin
      config_file = create_temp_for_install_switch unless action == 'uninstall'
      cmd_args << "/ConfigurationFile=\"#{config_file.path}\"" unless config_file.nil?
      res = try_execute(cmd_args, "Unable to #{action} features (#{features.join(', ')})", nil, [0, 1641, 3010])

      warn("#{action} of features (#{features.join(', ')} returned exit code 3010 - reboot required")  if res.exitstatus == 3010
      warn("#{action} of features (#{features.join(', ')} returned exit code 1641 - reboot initiated") if res.exitstatus == 1641
    ensure
      if config_file
        config_file.close
        config_file.unlink
      end
    end
  end

  def create_temp_for_install_switch
    if not_nil_and_not_empty? @resource[:install_switches]
      config_file = ['[OPTIONS]']
      @resource[:install_switches].each_pair do |k, v|
        if FEATURE_RESERVED_SWITCHES.include? k
          warn("Reserved switch [#{k}] found for `install_switches`, please know the provided value may be overridden by some command line arguments")
        end
        config_file << if v.is_a?(Numeric) || (v.is_a?(String) && v =~ %r{^(true|false|1|0)$}i)
                         "#{k}=#{v}"
                       elsif v.nil?
                         k
                       else
                         "#{k}=\"#{v}\""
                       end
      end
      config_temp = Tempfile.new(['sqlconfig', '.ini'])
      config_temp.write(config_file.join("\n"))
      config_temp.flush
      config_temp.close
      return config_temp
    end
    nil
  end

  def install_net_35(source_location = nil)
    Puppet::Provider::Sqlserver.run_install_dot_net(source_location)
  end

  def create
    if @resource[:features].empty?
      warn 'Uninstalling all sql server features not tied into an instance because an empty array was passed, please use ensure absent instead.'
      destroy
    else

      instance_version = PuppetX::Sqlserver::ServerHelper.sql_version_from_install_source(@resource[:source])
      Puppet.debug("Installation source detected as version #{instance_version}") unless instance_version.nil?

      install_net_35(@resource[:windows_feature_source]) unless [SQL_2016, SQL_2017, SQL_2019].include? instance_version

      debug "Installing features #{@resource[:features]}"
      add_features(@resource[:features])
      @property_hash[:features] = @resource[:features]
    end
  end

  def destroy
    remove_features(current_installed_features)
    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  mk_resource_methods

  def exists?
    @property_hash[:ensure] == :present || false
  end

  def current_installed_features
    @property_hash[:features]
  end

  def features=(new_features)
    if exists?
      remove_features(@property_hash[:features] - new_features)
      add_features(new_features - @property_hash[:features])
    end
    @property_hash[:features] = new_features
    features
  end
end
