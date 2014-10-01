require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql'))

Puppet::Type::type(:mssql_login).provide(:mssql, :parent => Puppet::Provider::Mssql) do


  def self.instances
    instances = []
    #need to exec with files and temp files to lookup based on templates
    Dir.glob("C:/Program Files/Microsoft SQL Server/.puppet/*.cfg", File::FNM_DOTMATCH).each { |config|
      debug("Parsing for logins in #{config}")
      instance = /.puppet\/\.(?<instance>.+)\.cfg$/.match(config)
      debug("Running against #{instance['instance']}")
      output = run_authenticated_sqlcmd(
          "SELECT name,
            type,
            type_desc,
            is_disabled,
            default_database_name,
            default_language_name,
            is_policy_checked,
            is_expiration_checked,
            password_hash
            FROM sys.sql_logins",
          {:instance_name => instance['instance']}
      )

      debug("Output from run_authenticated_sqlcmd = #{output}")

      users = output.split("/n")

      return [] if users.nil?
      users.each do |user|
        debug "Parsing user #{user}"
        name, login_type, type_desc, is_disabled,
            default_db, default_lang, policy_check, expire_check,
            password_hash =
            user.split(',', 9)
        if !(name.nil?)
          create = {
              :ensure => :present,
              :name => name,
              :login_type => login_type == "S" ? :SqlLogin : :WindowsUser,
              :default_database => default_db,
              :check_expiration => expire_check == 1 ? :ON : :OFF,
              :check_policy => policy_check == 1 ? :ON : :OFF
          }
          debug "Creating user object #{create}"
          instances << new(create)
        end
      end
    }
    instances
  end

  def self.prefetch(resources)
    users = instances
    debug "Prefetching for #{resources}, in #{users}"
    resources.keys.each do |name|
      debug "Resource key #{name}"
      if provider = users.find { |user| debug "User login is #{user.name}"; user.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    name = resource[:name]
    login_type = resource[:login_type]
    login_create_option = resource[:login_create_option]
    password = resource[:password]
    default_database = resource[:default_database]
    check_expiration = resource[:check_expiration]
    check_policy = resource[:check_policy]
    instance_name = resource[:instance_name]
    debug "Checking resource type of #{login_type} with #{login_create_option}"

    query = "CREATE LOGIN [#{name}] "
    if login_type == :WindowsUser
      query += "FROM WINDOWS WITH "
    else
      query += "WITH PASSWORD = '#{password}', "
      query += "CHECK_EXPIRATION = #{check_expiration.to_s.upcase}, "
      query += "CHECK_POLICY = #{check_policy.to_s.upcase},"
    end
    query += "DEFAULT_DATABASE = #{default_database}, "
    query += "DEFAULT_LANGUAGE = us_english;"

    opts = query_opts(resource)

    debug " Firing off query #{query} with options #{opts}"
    result = run_query(query, opts)
    debug "Result of sqlquery is #{result}"
    if /invalid syntax/.match(result)
      fail("Invalid syntax found, result from query is #{result}")
    end
    return result
  end

  mk_resource_methods

  def query_opts(resource)
    {:admin_user => resource[:admin_user],
     :admin_pass => "'#{resource[:admin_pass]}'",
     :default_database => resource[:default_database]}

  end

  def exists?
    debug "Testing exists is #{@property_hash[:ensure] == :present}"
  end

end
