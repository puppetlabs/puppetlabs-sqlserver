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
    debug "Removing features #{features}"
    modify_features('uninstall', features) unless features.empty?
  end

  def add_features(features)
    debug "Adding features #{features}"
    modify_features('install', features) unless features.empty?
  end

  def modify_features(action, features)
    cmd_args = ["#{@resource[:source]}/setup.exe",
                "/ACTION=#{action}",
                '/Q',
                '/IACCEPTSQLSERVERLICENSETERMS',
                "/FEATURES=#{features.join(',')}"]

    if !@resource[:pid].nil? && !@resource[:pid].empty? && action != 'uninstall'
      cmd_args << "/PID=#{@resource[:pid]}"
    end
    execute(cmd_args.compact)
  end

  def installNet35
    discovery = File.readlines(File.expand_path(File.join(File.dirname(__FILE__), '../../../../files/install_dot_net_35.ps1')))
    result = powershell([discovery])
  end

  def create
    installNet35
    debug "Installing features #{@resource[:features]}"
    add_features(@resource[:features])
    @property_hash[:features] = @resource[:features]
  end

  def destroy
    remove_features(@resource[:features])
    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  mk_resource_methods

  def exists?
    return @property_hash[:ensure] == :present || false
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
