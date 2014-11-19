require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql'))

Puppet::Type::type(:mssql_instance).provide(:mssql, :parent => Puppet::Provider::Mssql) do

  def self.instances
    instances = []
    discovery = File.readlines(File.expand_path(File.join(File.dirname(__FILE__), '../../../../files/run_discovery.ps1')))
    result = powershell([discovery])
    jsonResult = JSON.parse(result)
    debug "Parsing json result #{jsonResult}"
    if jsonResult.has_key?('instances')
      jsonResult['instances'].each do |instance_name|
        existing_instance = {:name => instance_name,
                             :ensure => :present,
                             :features =>
                                 PuppetX::Mssql::ServerHelper.translate_features(
                                     jsonResult[instance_name]['features']).sort!
        }
        instance = new(existing_instance)
        instances << instance
      end
    end
    instances
  end

  def self.prefetch(resources)
    my_instances = instances
    resources.keys.each do |name|
      if provider = my_instances.find { |inst| inst.name == name }
        resources[name].provider = provider
      end
    end
  end

  def remove_features(features)
    debug "Removing features #{features}"
    if !features.nil? and !(features.empty?)
      try_execute(basic_cmd_args('uninstall', features), "Error trying to remove features (#{features.join(', ')}")
    end
  end

  def add_features(features)
    debug "Installing features #{features}"
    cmd_args = build_cmd_args(features)
    try_execute(cmd_args, "Error trying to add features (#{features.join(', ')}")
  end

  def installNet35
    discovery = File.readlines(File.expand_path(File.join(File.dirname(__FILE__), '../../../../files/install_dot_net_35.ps1')))
    result = powershell([discovery])
  end

  def create
    if @resource[:features].empty?
      warn "Uninstalling all features for instance #{@resource[:name]} because an empty array was passed, please use ensure absent instead."
      destroy
    else
      installNet35
      cmd_args = build_cmd_args(@resource[:features])
      try_execute(cmd_args)
    end
  end

  def basic_cmd_args(action, features = [])
    cmd_args = ["#{@resource[:source]}/setup.exe",
                "/ACTION=#{action}",
                '/Q',
                '/IACCEPTSQLSERVERLICENSETERMS',
                "/INSTANCENAME=#{@resource[:name]}"]
    cmd_args << "/FEATURES=#{features.join(',')}" unless features.empty?
  end

  def build_cmd_args(features, action="install")
    cmd_args = basic_cmd_args(action, features)
    (@resource.parameters.keys - %i( ensure loglevel features name provider source sql_sysadmin_accounts sql_security_mode)).sort.collect do |key|
      cmd_args << "/#{key.to_s.gsub(/_/, '').upcase}=\"#{@resource[key]}\""
    end
    if  !@resource[:sql_sysadmin_accounts].nil? && !@resource[:sql_sysadmin_accounts].empty?
      if @resource[:sql_sysadmin_accounts].kind_of?(Array)
        cmd_args << "/SQLSYSADMINACCOUNTS=#{ Array.new(@resource[:sql_sysadmin_accounts]).collect { |account| "\"#{account}\"" }.join(' ')}"
      else
        cmd_args << "/SQLSYSADMINACCOUNTS=\"#{@resource[:sql_sysadmin_accounts]}\""
      end
    end
    cmd_args
  end

  def destroy
    cmd_args = basic_cmd_args("uninstall", current_installed_features)
    try_execute(cmd_args, "Unable to uninstall instance #{@resource[:name]}")
    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  mk_resource_methods

  def exists?
    return @property_hash[:ensure] == :present || false
  end

  def current_installed_features
    @property_hash[:features]
  end

  def features=(new_features)
    if exists?
      remove_features(@property_hash[:features] - new_features)
      add_features (new_features - @property_hash[:features])
    end
    @property_hash[:features] = new_features
    self.features
  end

end
