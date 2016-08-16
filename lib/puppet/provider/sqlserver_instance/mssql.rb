require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver'))


INSTANCE_RESERVED_SWITCHES =
  %w(AGTSVCACCOUNT AGTSVCPASSWORD ASSVCACCOUNT AGTSVCPASSWORD PID
       RSSVCACCOUNT RSSVCPASSWORD SAPWD SECURITYMODE SQLSYSADMINACCOUNTS FEATURES)

Puppet::Type::type(:sqlserver_instance).provide(:mssql, :parent => Puppet::Provider::Sqlserver) do
  def self.instances
    instances = []
    result = Facter.value(:sqlserver_instances)
    debug "Parsing result #{result}"
    result = result.values.inject(:merge)
    result.keys.each do |instance_name|
        existing_instance = {:name => instance_name,
                             :ensure => :present,
                             :features => result[instance_name]['features'].sort
        }
        instance = new(existing_instance)
        instances << instance
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
      cmd_args = build_cmd_args(features, action)
      begin
        config_file = create_temp_for_install_switch unless action == 'uninstall'
        cmd_args << "/ConfigurationFile=\"#{config_file.path}\"" unless config_file.nil?
        try_execute(cmd_args, "Error trying to #{action} features (#{features.join(', ')}")
      ensure
        if config_file
          config_file.close
          config_file.unlink
        end
      end
    end
  end

  def installNet35(source_location = nil)
    result = Puppet::Provider::Sqlserver.run_install_dot_net(source_location)
  end

  def create
    if @resource[:features].empty?
      warn "Uninstalling all features for instance #{@resource[:name]} because an empty array was passed, please use ensure absent instead."
      destroy
    else
      installNet35(@resource[:windows_feature_source])
      add_features(@resource[:features])
      # cmd_args = build_cmd_args(@resource[:features])
      # begin
      #   config_file = create_temp_for_install_switch
      #   cmd_args << "/ConfigurationFile=\"#{config_file.path}\"" unless config_file.nil?
      #   try_execute(cmd_args)
      # ensure
      #   if config_file
      #     config_file.close
      #     config_file.unlink
      #   end
      # end
    end
  end

  def create_temp_for_install_switch
    if not_nil_and_not_empty? @resource[:install_switches]
      config_file = ["[OPTIONS]"]
      @resource[:install_switches].each_pair do |k, v|
        if INSTANCE_RESERVED_SWITCHES.include? k
          warn("Reserved switch [#{k}] found for `install_switches`, please know the provided value
may be overridden by some command line arguments")
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
      %w(pid sa_pwd sql_svc_account sql_svc_password agt_svc_account agt_svc_password as_svc_account as_svc_password rs_svc_account rs_svc_password security_mode).map(&:to_sym).sort.collect do |key|
        if not_nil_and_not_empty? @resource[key]
          cmd_args << "/#{key.to_s.gsub(/_/, '').upcase}=\"#{@resource[key]}\""
        end
      end

      format_cmd_args_array('/SQLSYSADMINACCOUNTS', @resource[:sql_sysadmin_accounts], cmd_args, true)
      format_cmd_args_array('/ASSYSADMINACCOUNTS', @resource[:as_sysadmin_accounts], cmd_args)
    end
    cmd_args
  end

  def format_cmd_args_array(switch, arr, cmd_args, use_discrete = false)
    if not_nil_and_not_empty? arr
      arr = [arr] if !arr.kind_of?(Array)

      # The default action is to join the array elements with a space ' ' so the cmd_args ends up like;
      # ["/SWITCH=\"Element1\" \"Element2\""]
      # Whereas if use_discrete is set, the args are appended as discrete elements in the cmd_args array e.g.;
      # ["/SWITCH=\"Element1\"","\"Element2\""]

      if use_discrete
        arr.map.with_index { |var,i|
          if i == 0
            cmd_args << "#{switch}=\"#{var}\""
          else
            cmd_args << "\"#{var}\""
          end
        }
      else
        cmd_args << "#{switch}=#{arr.collect { |item| "\"#{item}\"" }.join(' ')}"
      end
    end
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
