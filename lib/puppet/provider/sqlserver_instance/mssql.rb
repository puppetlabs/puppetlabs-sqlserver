require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql'))

Puppet::Type::type(:sqlserver_instance).provide(:mssql, :parent => Puppet::Provider::Mssql) do

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
    modify_features(features, 'uninstall')
  end

  def add_features(features)
    modify_features(features, 'install')
  end

  def modify_features(features, action)
    if not_nil_and_not_empty? features
      debug "#{action.capitalize}ing features '#{features.join(',')}'"
      try_execute(build_cmd_args(features, action), "Error trying to #{action} features (#{features.join(', ')}")
    end
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

  def basic_cmd_args(features, action)
    cmd_args = ["#{@resource[:source]}/setup.exe",
                "/ACTION=#{action}",
                '/Q',
                '/IACCEPTSQLSERVERLICENSETERMS',
                "/INSTANCENAME=#{@resource[:name]}"]
    cmd_args << "/FEATURES=#{features.join(',')}" unless features.empty?
  end

  def build_cmd_args(features, action="install")
    cmd_args = basic_cmd_args(features, action)
    if action == 'install'
      (@resource.parameters.keys - %w(ensure loglevel features name provider source sql_sysadmin_accounts sql_security_mode).map(&:to_sym)).sort.collect do |key|
        cmd_args << "/#{key.to_s.gsub(/_/, '').upcase}=\"#{@resource[key]}\""
      end
      if not_nil_and_not_empty? @resource[:sql_sysadmin_accounts]
        if @resource[:sql_sysadmin_accounts].kind_of?(Array)
          cmd_args << "/SQLSYSADMINACCOUNTS=#{ Array.new(@resource[:sql_sysadmin_accounts]).collect { |account| "\"#{account}\"" }.join(' ')}"
        else
          cmd_args << "/SQLSYSADMINACCOUNTS=\"#{@resource[:sql_sysadmin_accounts]}\""
        end
      end
    end
    cmd_args
  end

  def destroy
    cmd_args = basic_cmd_args(current_installed_features, 'uninstall')
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
