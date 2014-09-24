require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql'))

Puppet::Type::type(:mssql_login).provide(:mssql, :parent => Puppet::Provider::Mssql) do


  def self.instances
    instances = []
    users = sqlcmd(create_sqlcmd_query(
                       'SELECT name,type,type_desc,is_disabled,default_database_name, default_language_name, is_policy_checked, is_expiration_checked, password_hash FROM sys.sql_logins',
                       {:admin_user => 'sa',
                        :admin_pass => "'P@ssword1'",
                        :default_database => 'master'}
                   )
    ).split("\n")
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

  def run_create_query(query, opts = {})
    run_query(Puppet::Provider::Mssql.create_sqlcmd_query(query, opts))
  end

  def run_select_query(query, opts={})
    run_query(Puppet::Provider::Mssql.select_sqlcmd_query(query, opts))
  end

  def run_query(queryarray)
    return sqlcmd(queryarray)
  end

  def exists?
    debug "Testing exists is #{@property_hash[:ensure] == :present}"
    user =
        run_select_query(
            # change to sys.server_principals
            "SELECT name,type,type_desc,is_disabled,default_database_name, default_language_name, is_policy_checked, is_expiration_checked, password_hash FROM sys.sql_logins WHERE name = '#{resource[:name]}'",
            query_opts(resource)
        ).split("\n")
    user.nil?
  end

end
