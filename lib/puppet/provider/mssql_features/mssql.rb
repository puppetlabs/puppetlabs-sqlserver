require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql'))

Puppet::Type::type(:mssql_features).provide(:mssql, :parent => Puppet::Provider::Mssql) do

  def self.instances
    instances = []
    discovery = File.readlines(File.expand_path(File.join(File.dirname(__FILE__), '../../../../files/run_discovery.ps1')))
    result = powershell([discovery])
    jsonResult = JSON.parse(result)
    debug "Parsing json result #{jsonResult}"
    if jsonResult.has_key?('Generic Features')
      existing_instance = {:name => "Generic Features",
                           :ensure => :present,
                           :features =>
                               PuppetX::Mssql::ServerHelper.translate_features(
                                   jsonResult['Generic Features']).sort!
      }
      debug "Parsed features = #{existing_instance[:features]}"

      instance = new(existing_instance)
      debug "Created instance #{instance}"
      instances << instance
    end
    instances
  end

  def self.prefetch(resources)
    features = instances
    resources.keys.each do |name|
      if provider = features.find { |feature| feature.name == name }
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
    if not_nil_and_not_empty? features
      debug "#{action.capitalize}ing features '#{features.join(',')}'"
      cmd_args = ["#{@resource[:source]}/setup.exe",
                  "/ACTION=#{action}",
                  '/Q',
                  '/IACCEPTSQLSERVERLICENSETERMS',
                  "/FEATURES=#{features.join(',')}"]

      if not_nil_and_not_empty?(@resource[:pid]) && action != 'uninstall'
        cmd_args << "/PID=#{@resource[:pid]}"
      end
      try_execute(cmd_args, "Unable to #{action} features (#{features.join(', ')})")
    end
  end

  def installNet35
    discovery = File.readlines(File.expand_path(File.join(File.dirname(__FILE__), '../../../../files/install_dot_net_35.ps1')))
    result = powershell([discovery])
  end

  def create
    if @resource[:features].empty?
      warn "Uninstalling all sql server features not tied into an instance because an empty array was passed, please use ensure absent instead."
      destroy
    else
      installNet35
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

