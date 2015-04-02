# sqlserver

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with sqlserver](#setup)
    * [What sqlserver affects](#what-sqlserver-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with sqlserver](#beginning-with-sqlserver)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

The sqlserver module installs and manages Microsoft SQL Server 2012 and 2014 on Windows systems.

##Module Description

The sqlserver module adds defined types to install and manage Microsoft SQL Server 2012 and 2014 on Windows Server 2012. The module can install SQL Server clients, multiple instances, and SQL features, as well as create and manage new databases and logins.

##Setup

###What sqlserver affects

This module requires .NET 3.5 and installs it if it's not already on your system. This might require an internet connection.

###Setup Requirements

The sqlserver module requires the following:

* Puppet Enterprise 3.7 or later
* Puppet Supported `acl` [module](https://forge.puppetlabs.com/puppetlabs/acl)
* .NET 3.5
* ISO, mounted or expanded either locally or on a network share
* Windows Server 2012 or 2012R2

###Beginning with sqlserver

To get started with the sqlserver module, include these settings in your manifest:

```
sqlserver_instance{'MSSQLSERVER':
    features                => ['SQL'],
    source                  => 'E:/',
    sql_sysadmin_accounts   => ['myuser'],
}
```

This manifest installs MS SQL and creates an MS SQL instance named MSSQLSERVER. It installs the base SQL feature set (Data Quality, FullText, Replication, and SQLEngine), specifies the location of the setup.exe, and creates a new SQL-only sysadmin, 'myuser'.

##Usage

Note: For clarification on Microsoft SQL Server terminology, please see [Microsoft SQL Server Terms](#microsoft-sql-server-terms) below.

###To install SQL Server tools and features not specific to a database instance:

```
sqlserver_features { 'Generic Features':
	source		=> 'E:/',
	features 	=> ['Tools'],
}
```

```
sqlserver_features { 'Generic Features':
	source		=> 'E:/',
	features 	=> ['ADV_SSMS', 'BC', 'Conn', 'SDK', 'SSMS'],
}
```

###To create a new database in an instance:

```
sqlserver::database{ 'minviable':
    instance => 'MSSQLSERVER',
}
```

###To set up a new login:

```
SQL Login
sqlserver::login{'vagrant':
	instance => 'MSSQLSERVER',
	password => 'Pupp3t1@',
}

Windows Login
sqlserver::login{'WIN-D95P1A3V103\localAccount':
	instance 	=> 'MSSQLSERVER',
	login_type 	=> 'WINDOWS_LOGIN',
}
```

###To create a new login and a user for a given database
```
sqlserver::login{'loggingUser':
    password => 'Pupp3t1@',
}

sqlserver::user{'rp_logging-loggingUser':
    user     => 'loggingUser',
    database => 'rp_logging',
    require  => Sqlserver::Login['loggingUser'],
}
```

###To manage the above users permission
```
sqlserver::user::permission{'INSERT-loggingUser-On-rp_logging':
    user       => 'loggingUser',
    database   => 'rp_logging',
    permission => 'INSERT',
    require    => Sqlserver::User['rp_logging-loggingUser'],
}

sqlserver::user::permission{'Deny the Update as we should only insert':
    user       => 'loggingUser',
    database   => 'rp_logging',
    permission => 'UPDATE',
    state      => 'DENY',
    require    => Sqlserver::User['rp_logging-loggingUser'],
}
```

###To run custom TSQL statements:

To use `sqlserver_tsql` to trigger other classes or defined types:

```
sqlserver_tsql{ 'Query Logging DB Status':
    instance => 'MSSQLSERVER',
    onlyif   => "IF (SELECT count(*) FROM myDb.dbo.logging_table WHERE
        message like 'FATAL%') > 1000  THROW 50000, 'Fatal Exceptions in Logging', 10",
    notify   => Exec['Too Many Fatal Errors']
}
```

To clean up regular logs with conditional checks:

```
sqlserver_tsql{ 'Cleanup Old Logs':
    instance => 'MSSQLSERVER',
    command  => "DELETE FROM myDb.dbo.logging_table WHERE log_date < '${log_max_date}'",
    onlyif   => "IF exists(SELECT * FROM myDb.dbo.logging_table WHERE log_date < '${log_max_date}')
        THROW 50000, 'need log cleanup', 10",
}
```

If you want something to always execute, you can leave out the `onlyif` parameter:

```
sqlserver_tsql{ 'Always running':
    instance => 'MSSQLSERVER',
    command  => 'EXEC notified_executor()',
}
```

#### Windows SQL Server Terms

Terminology differs somewhat between various database systems; please refer to this list of terms for clarification.

* Instance: An instance is an installed and running database service.
* Database: A database is a collection of information organized into related tables of data and definitions of data objects.
* Login: A Login has server-level permissions to access and manage all or some of the database and principal login rights.
* User: A User has database-level access to a single database and is typically mapped to a Login.
* Server Roles: Server-level permission groups that exist outside of databases. These are defined by SQL Server and might have nested permissions.

##Reference

### Types

#### sqlserver_features

* `ensure`: Ensures that the resource is present. Valid values are 'present', 'absent'.
* `features`: Specifies features to install or uninstall. The list of top-level features include IS, MDS, and Tools. The Tools feature will install Management Tools, SQL Server Data Tools, and other shared components. Valid values are 'Tools', 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS'.
* `is_svc_account`: Either domain user name or system account. Defaults to 'NT AUTHORITY\NETWORK SERVICE'.
* `is_svc_password`: Password for domain user.
* `pid`: Specify the SQL Server product key to configure which edition you would like to use. Can be left empty for evaluation versions.
* `install_switches`: Hash of optional installer switches for SQL Server setup.

  Please note that if an option is set in both its own specific parameter and `install_switches`, the specifically named parameter takes precedence. For example, if you set the product key in both `pid` and in `install_switches`, the `pid` parameter will be honored.

For more information about installer switches and configuration, see the links below:

* [Installer Switches](https://msdn.microsoft.com/en-us/library/ms144259.aspx)
* [Configuration File](https://msdn.microsoft.com/en-us/library/dd239405.aspx)

#### sqlserver_instance

* `agt_svc_account`: Either domain user name or system account.
* `agt_svc_password`: Password for domain user name. Not required for system account.
* `as_svc_account`: The account used by the Analysis Services service.
* `as_svc_password`: The password for the Analysis Services service account.
* `as_sysadmin_accounts`: Specifies the list of administrator accounts to provision.
* `ensure`: Ensure whether the resource is present. Valid values are `present`, `absent`.
* `features`: Specifies features to install, uninstall. The list of top-level features include SQL, AS, and RS. The SQL feature installs the Database Engine, Replication, Full-Text, and Data Quality Services (DQS) server.  Valid values are 'SQL', 'SQLEngine', 'Replication', 'FullText', 'DQ', 'AS', 'RS'.
* `name`: The name for the instance.
* `pid`: Specify the SQL Server product key to configure which edition you would like to use.
* `rs_svc_account`: Specify the service account of the report server. This value is required. If you omit this value, Setup uses the default built-in account for the current operating system (either NetworkService or LocalSystem). If you specify a domain user account, the domain must be under 254 characters and the user name must be under 20 characters. The account name cannot contain the following characters: '"/ \ [ ] : ; | = , + * ? < >'.
* `rs_svc_password`: Specify a strong password for the account. A strong password is at least 8 characters and includes a combination of upper and lower case alphanumeric characters and at least one symbol character. Avoid spelling an actual word or name that might be listed in a dictionary.
* `sa_pwd`: Required when :security_mode => 'SQL'.
* `security_mode`:Specifies the security mode for SQL Server. If this parameter is not supplied, then Windows-only authentication mode is supported. Valid values are `SQL`.
* `service_ensure`: Setting this to `automatic` ensures running if stopped; `manual` sets the service to manual and takes no action on current state; `disable` stops and disables the service. Valid values are `automatic`, `manual`, `disable`.
* `source`: The drive where the ISO is mounted or expanded; can be a network share.
* `sql_svc_account`: Account for SQL Server service: Domain\User or system account.
* `sql_svc_password`: The SQL Server service password; required only for a domain account.
* `sql_sysadmin_accounts`: The Windows or SQL account(s) to provision as SQL Server system administrators.
* `install_switches`: Hash of optional installer switches for SQL Server instance setup.

  Please note that if an option is set in both its own specific parameter and `install_switches`, the specifically named parameter takes precedence. For example, if you set the product key in both `pid` and in `install_switches`, the `pid` parameter will be honored.

For more information about installer switches and configuration, see the links below:

* [Installer Switches](https://msdn.microsoft.com/en-us/library/ms144259.aspx)
* [Configuration File](https://msdn.microsoft.com/en-us/library/dd239405.aspx)

####sqlserver_tsql
* `command`: The TSQL statement to execute.
* `onlyif`: TSQL to execute as a check to see if we should proceed and run the command parameter, should encounter a throw or error to trigger
* `instance`: The SQL Server instance you want to execute against.

### Defined Types

#### `sqlserver::config`

Stores the config file that allows Puppet to access and modify the instance.

* `instance_name`: The instance name you want to manage.  Defaults to the name of the define.
* `admin_user`: The SQL login with sysadmin rights on the server, can only be login of SQL_Login type.
* `admin_pass`: The password to access the server to be managed.

  ```
  sqlserver::config{'MSSQLSERVER':
    admin_user => 'sa',
    admin_pass => 'PuppetP@ssword1',
    }
  ```

#### `sqlserver::database`

Creates, destroys, or updates databases, but does not move or modify files. Requires defined type `sqlserver::config` for the instance in which you want the database created.

* `db_name`: The name of the database you want to manage. Accepts a string.
* `instance`: The name of the instance to connect to. Instance names must be strings no longer than 16 characters.
* `ensure`: Ensures that the resource is present. Valid values are 'present', 'absent'. Defaults to 'present'.
* `compatibility`: Numeric representation of the SQL Server version with which the database should be compatible. For example, 100 = SQL Server 2008 through SQL Server 2012.  For a complete list of values, refer to [http://msdn.microsoft.com/en-us/library/bb510680.aspx](http://msdn.microsoft.com/en-us/library/bb510680.aspx).
* `collation_name`: Modifies dictionary default sort rules for the datatbase. Defaults to 'Latin1_General'. To find out what other values your system supports, run the query `SELECT * FROM sys.fn_helpcollations() WHERE name LIKE 'SQL%'`.
* `filestream_non_transacted_access`: Specifies the level of non-transactional FILESTREAM access to the database. This parameter is affected only at creation; updates will not change this setting. Valid values are 'OFF', 'READ_ONLY', 'FULL'. Requires defined type `sqlserver::sp_configure`.
* `filestream_directory_name`: Accepts a Windows-compatible directory name. This name should be unique among all the Database_Directory names in the SQL Server instance. Uniqueness comparison is case-insensitive, regardless of SQL Server collation settings. This option should be set before creating a FileTable in this database. This parameter is affected only at creation; updates will not change this setting. Requires defined type `sqlserver::sp_configure`.
* `filespec_name`: Specifies the logical name for the file. NAME is required when FILENAME is specified, except when specifying one of the FOR ATTACH clauses. A FILESTREAM filegroup cannot be named PRIMARY. This parameter is affected only at creation; updates will not change this setting.
* `filespec_filename`: Specifies the operating system (physical) file name. This parameter is affected only at creation; updates will not change this setting.
* `filespec_size`: Specifies the size of the file. The kilobyte (KB), megabyte (MB), gigabyte (GB), or terabyte (TB) suffixes can be used. The default is MB.  Values can not be greater than 2147483647. This parameter is affected only at creation; updates will not change this setting.
* `filespec maxsize`: Specifies the maximum size to which the file can grow. MAXSIZE cannot be specified when the os_file_name is specified as a UNC path. This parameter is affected only at creation; updates will not change this setting.
* `filespec_filegrowth`: Specifies the automatic growth increment of the file. The FILEGROWTH setting for a file cannot exceed the MAXSIZE setting. FILEGROWTH cannot be specified when the os_file_name is specified as a UNC path. FILEGROWTH does not apply to a FILESTREAM filegroup. This parameter is affected only at creation; updates will not change this setting.
* `log_name`: Specifies the logical name for the file. NAME is required when FILENAME is specified, except when specifying one of the FOR ATTACH clauses. A FILESTREAM filegroup cannot be named PRIMARY. This parameter is affected only at creation; updates will not change this setting.
* `log_filename`: Specifies the operating system (physical) file name. This parameter is affected only at creation; updates will not change this setting.
* `log_size`: Specifies the size of the file. The kilobyte (KB), megabyte (MB), gigabyte (GB), or terabyte (TB) suffixes can be used. The default is MB.  Values can not be greater than 2147483647. This parameter is affected only at creation; updates will not change this setting.
* `log_maxsize`: Specifies the maximum size to which the file can grow. MAXSIZE cannot be specified when the os_file_name is specified as a UNC path. This parameter is affected only at creation; updates will not change this setting.
* `log_filegrowth`: Specifies the automatic growth increment of the file. The FILEGROWTH setting for a file cannot exceed the MAXSIZE setting. FILEGROWTH cannot be specified when the os_file_name is specified as a UNC path. FILEGROWTH does not apply to a FILESTREAM filegroup. This parameter is affected only at creation; updates will not change this setting.
* `containment`: Defaults to 'NONE'.Other possible values are 'PARTIAL'. Setting `containment` =>'PARTIAL' requires defined type `sqlserver::sp_configure`. See [http://msdn.microsoft.com/en-us/library/ff929071.aspx](http://msdn.microsoft.com/en-us/library/ff929071.aspx) for complete documentation about containment.
* `default_fulltext_language`: Sets default fulltext language. Only applicable if `containment` => 'PARTIAL'. Valid values are documented at [http://msdn.microsoft.com/en-us/library/ms190303.aspx](http://msdn.microsoft.com/en-us/library/ms190303.aspx). Defaults to 'us_english'.
* `default_language`: Sets default language. Only applicable if `containment` => 'PARTIAL'. Valid values are documented at http://msdn.microsoft.com/en-us/library/ms190303.aspx. Defaults to 'us_english'.
* `nested_triggers`: Enables cascading triggers. Only applicable if `containment` => 'PARTIAL'. Valid values are 'ON', 'OFF'. See [http://msdn.microsoft.com/en-us/library/ms178101.aspx](http://msdn.microsoft.com/en-us/library/ms178101.aspx) for complete documentation.
* `transform_noise_words`: Removes noise or stop words, such as “is”, “the”, “this”. Only applicable if `containment` => 'PARTIAL'. Valid values are 'ON', 'OFF'.
* `two_digit_year_cutoff`: The year at which the system will treat the year as four digits instead of two. For example, if set to '1999', 1998 would be abbreviated to '98', while 2014 would be '2014'. Only applicable if `containment` => 'PARTIAL'. Valid values are any year between 1753 and 9999. Defaults to 2049.
* `db_chaining`: Whether the database can be the source or target of a cross-database ownership chain. Only applicable if `containment` => 'PARTIAL'. Valid values are 'ON', 'OFF'. Defaults to 'OFF'.
* `trustworthy`: Whether database modules (such as views, user-defined functions, or stored procedures) that use an impersonation context can access resources outside the database. Only applicable if `containment` => 'PARTIAL'. Valid values are 'ON', 'OFF'. Defaults to 'OFF'.

**For more information about these settings and configuration in Microsoft SQL Server, please see:**

* [Contained Databases](http://msdn.microsoft.com/en-us/library/ff929071.aspx)
* [Create Database TSQL](http://msdn.microsoft.com/en-us/library/ms176061.aspx)
* [Alter Database TSQL](http://msdn.microsoft.com/en-us/library/ms174269.aspx)
* [System Languages](http://msdn.microsoft.com/en-us/library/ms190303.aspx)

Note that FILESTREAM usage might require some manual MS SQL configuration. Please see [Enable and Configure FILESTREAM](http://msdn.microsoft.com/en-us/library/cc645923.aspx) for details.

#### `sqlserver::login`

Requires defined type `sqlserver::config`.

* `login`: The SQL or Windows login you want to manage.
* `instance`: The name of the instance to connect to. Instance names can not be longer than 16 characters
* `ensure`: Ensures that the resource is present. Valid values are 'present', 'absent'. Defaults to 'present'.
* `password`: Plain text password. Only applicable when Login_Type is equal to 'SQL_LOGIN'.
* `svrroles` Accepts a hash of preinstalled server roles that you want assigned to this login. For example, `'diskadmin' => 1, 'dbcreator' => 1, 'sysadmin' => 0,`. Valid values are listed at [http://msdn.microsoft.com/en-us/library/ms188659.aspx](http://msdn.microsoft.com/en-us/library/ms188659.aspx).
* `login_type`: Sets the type of login to use. Valid values are 'SQL_LOGIN', 'WINDOWS_LOGIN'. Defaults to 'SQL_LOGIN'.
* `default_database`: Sets the database the login should default to when connecting. Defaults to 'master'.
* `default_language`: Sets default language. Valid values are documented at http://msdn.microsoft.com/en-us/library/ms190303.aspx. Defaults to 'us_english'.
* `check_expiration`: For SQL logins, checks to see if password has expired and user should be forced to change the password. Only applicable when Login_Type = 'SQL_LOGIN'. Valid values are 'true', 'false'. Default value is 'false'.
* `check_policy`: Checks the password policy. Only applicable when Login_Type = 'SQL_LOGIN'. Valid values are 'true', 'false'. Defaults to 'true'.
* `disabled`: Valid values are 'true', 'false'. Defaults to 'false'.

**For more information about these settings and configuration in Microsoft SQL Server, please see:**

* [Server Role Members](http://msdn.microsoft.com/en-us/library/ms186320.aspx)
* [Create Login](http://technet.microsoft.com/en-us/library/ms189751.aspx)
* [Alter Login](http://technet.microsoft.com/en-us/library/ms189828.aspx)

#### `sqlserver::login::permission`

* `login`: The SQL or Windows login you want to manage.
* `permission`: The permission you would like managed. i.e. 'SELECT', 'INSERT', 'UPDATE', 'DELETE'
* `state`: The stat you would like the permission to be in.  Accepts 'GRANT', 'DENY', 'REVOKE'.  Please not that REVOKE equates to absent and will default ot the database, role and system levels.
* `with_grant_option`: Whether to give the user the option to grant this permission to other users, accepts true or false, defaults to false
* `instance`: The name of the instance to connect to. Instance names can not be longer than 16 characters

#### `sqlserver::user`

Requires defined type `sqlserver::config`

* `user`: The username you would like to manage.
* `database`: The database you want the user created on.
* `login`: The login to associate the database user with.  If left blank SQL Server will assume the user and login are the same.
* `instance`: The named of the instance you want to have the user created on. Defaults to 'MSSQLSERVER'
* `password`: The password to assign to the user.  The database must have `containment` set to 'PARTIAL' in order to accept user level passwords
* `default_schema`: The schema that should be default when the user connects.  Default for SQL Server is 'dbo' but can be configured on server level.

#### `sqlserver::user::permission`

Requires defined type `sqlserver::config`

* `user`: The username you would like to manage.
* `database`: The database you wanted it manged on.
* `permissions`: An array of permissions you would like managed. i.e. ['SELECT', 'INSERT', 'UPDATE', 'DELETE']
* `state`: The state you would like the permission in.  Accepts 'GRANT', 'DENY', 'REVOKE' Please note that REVOKE equates to absent and will default to database and system level permissions.
* `with_grant_option`: Whether to give the user the option to grant this permission to other users, accepts true or false, defaults to false
* `instance`: THe name of the instance where the user and database exists. Defaults to 'MSSQLSERVER'

**For more information about these settings and permissions in Microsoft SQL Server, please see:**

* [Permissions (Database Engine)](https://msdn.microsoft.com/en-us/library/ms191291.aspx)
* [Grant Database Permissions](https://msdn.microsoft.com/en-us/library/ms178569.aspx)


#### `sqlserver::user`

Requires defined type `sqlserver::config`

* `user`: The username you want to manage, defaults to the title
* `database`: The database you want the user to be managed on.
* `ensure`: Whether you want the user toe be 'present' or 'absent'.  Defaults to 'present'
* `default_schema`: SQL schema or namespace you would like to default to, typically 'dbo'
* `instance`: The named instance you want to manage against
* `login`: The login to associate the user with, by default SQL Server will assume the user and login match if left empty
* `password`: The password for the user, can only be used when the database is a contained database.

* [Contained Databases](http://msdn.microsoft.com/en-us/library/ff929071.aspx)

#### `sqlserver::user::permission`

Requires defined type `sqlserver::config`

* `user`: The username for which the permission will be manage.
* `database`: The database you would like the permission managed on.
* `permissions`: An array of permissions you would like managed. i.e. ['SELECT', 'INSERT', 'UPDATE', 'DELETE']
* `state`: The stat you would like the permission to be in.  Accepts 'GRANT', 'DENY', 'REVOKE'.  Please not that REVOKE equates to absent and will default ot the database, role and system levels.
* `with_grant_option`: Whether to give the user the option to grant this permission to other users, accepts true or false, defaults to false
* `instance`: The name of the instance to connect to. Instance names can not be longer than 16 characters

#### `sqlserver::role`

Requires defined type `sqlserver::config`

* `role`: The unique name you want the role to be created under
* `ensure`: Whether it should be absent or present.
* `instance`: The named instance you want to manage against
* `authorization`: The login/user that should be the owning party for the Role
* `type`: Whether the Role to be created is `SERVER` or `DATABASE`
* `database`: The name of the database you want the role to be created for when specifying `type => 'DATABASE'`
* `permissions`: A hash of permissions that should be managed for the role.  Valid keys are 'GRANT', 'GRANT_WITH_OPTION', 'DENY' or 'REVOKE'.  Valid values must be an array of Strings i.e. {'GRANT' => ['CONNECT', 'CREATE ANY DATABASE'] }
* `members`: An array of logins/users that should be members of the role.
* `members_purge`: If set to true we will DROP any members not listed in the array.  If an empty array provided we will drop all members. Default: false

#### `sqlserver::role::permissions`

Requires defined type `sqlserver::config`

* `role`: The name of the role you want permissions to be managed for.
* `permissions`: An array of permissions you want manged for the given role
* `state`: The stat you would like the permission to be in.  Accepts 'GRANT', 'DENY', 'REVOKE'.  Please not that REVOKE equates to absent and will default ot the database, role and system levels.
* `with_grant_option`: Whether to give the user the option to grant this permission to other users, accepts true or false, defaults to false, `state` must be 'GRANT' in order to be set to true
* `type`: Whether the Role is `SERVER` or `DATABASE` level
* `database`: The name of the database you want the role to be created for when specifying `type => 'DATABASE'`
* `instance`: The named instance you want to manage against

#### `sqlserver::sp_configure`

This defined type configures the instance to allow usage of filestream parameters or partial containment. Requires defined type `sqlserver::config`.

* `config_name`: The config name that you want to update in sys.configurations.
* `value`: The value for the given `config_name`. Must be an integer value; some `config_name`, the `value` might require minimum and maximum values.
* `instance`: The name of the instance you want to configure.
* `reconfigure`: Runs RECONFIGURE on the server after the `value` is updated. Defaults to 'true'.
* `restart`: Monitors the the service for changes; if changes occur, restarts the service. Defaults to 'false'.
* `with_override`: Confirms that you want to force `reconfigure`. Defaults to 'false'.

**For more information about these settings and configuration in Microsoft SQL Server, please see:**

* [Reconfigure](http://msdn.microsoft.com/en-us/library/ms176069.aspx)
* [Server Configuration Options](http://msdn.microsoft.com/en-us/library/ms189631.aspx)

##Limitations

This module is available only for Puppet Enterprise 3.7 and later.

## Development

This is a proprietary module only available to Puppet Enterprise users. As such, we have no formal way for users to contribute toward development. However, we know our users are a charming collection of brilliant people, so if you have a bug you've fixed or a contribution to this module, please generate a diff and throw it into a ticket to support---they'll ensure that we get it.
