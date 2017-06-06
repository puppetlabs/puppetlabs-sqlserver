require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x/sqlserver/server_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x/sqlserver/features'))

FEATURE_RESERVED_SWITCHES =
  %w(AGTSVCACCOUNT AGTSVCPASSWORD ASSVCACCOUNT AGTSVCPASSWORD PID
       RSSVCACCOUNT RSSVCPASSWORD SAPWD SECURITYMODE SQLSYSADMINACCOUNTS FEATURES)

Puppet::Type::type(:sqlserver_features).provide(:mssql, :parent => Puppet::Provider::Sqlserver) do
  def self.instances
    instances = []
    result = Facter.value(:sqlserver_features)
    debug "Parsing result #{result}"

    [SQL_2012, SQL_2014, SQL_2016].each do |sql_version|
      next if result[sql_version].empty?
      instance_props = {:name => "Generic Features #{sql_version}",
                        :ensure => :present,
                        :features => result[sql_version].sort
      }
      debug "Parsed features = #{instance_props[:features]}"

      instance = new(instance_props)
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

fail "#{cmd_args} WOOP WOOP WOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOPWOOP WOOP"

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
  end

  def create_temp_for_install_switch
    if not_nil_and_not_empty? @resource[:install_switches]
      config_file = ["[OPTIONS]"]
      @resource[:install_switches].each_pair do |k, v|
        if FEATURE_RESERVED_SWITCHES.include? k
          warn("Reserved switch [#{k}] found for `install_switches`, please know the provided value may be overridden by some command line arguments")
        end
        if v.is_a?(Numeric) || (v.is_a?(String) && v =~ /^(true|false|1|0)$/i)
          config_file << "#{k}=#{v}"
        elsif v.nil?
          config_file << k
        else
          config_file << "#{k}=\"#{v}\""
        end
      end
      config_temp = Tempfile.new(['sqlconfig', '.ini'])
      config_temp.write(config_file.join("\n"))
      config_temp.flush
      config_temp.close
      return config_temp
    end
    return nil
  end

  def installNet35(source_location = nil)
    result = Puppet::Provider::Sqlserver.run_install_dot_net(source_location)
  end

  def create
    if @resource[:instance_version].nil? || @resource[:instance_version] == :auto
      instance_version = PuppetX::Sqlserver::ServerHelper.sql_version_from_install_source(@resource[:source])
      Puppet.debug("Instance version detected as #{instance_version}")
    else
      instance_version = @resource[:instance_version]
      Puppet.debug("Instance version set as #{instance_version}")
    end

    # Check if features have been requested but cannot be installed, as they don't exist in this version
    invalid_features = feature_list - PuppetX::Sqlserver::Features.valid_shared_features(instance_version)
    fail "#{invalid_features.join(', ')} are not valid for the sqlserver_features of type '#{instance_version}'" unless invalid_features.length == 0

    if feature_list.empty?
      warn "Uninstalling all sql server features not tied into an instance because an empty array was passed, please use ensure absent instead."
      destroy
    else
      installNet35(@resource[:windows_feature_source]) unless instance_version == SQL_2016
      debug "Installing features #{feature_list}"
      add_features(feature_list)
      @property_hash[:features] = feature_list
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

