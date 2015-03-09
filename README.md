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
    instance => ‘MSSQLSERVER’,
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

  Please note that if an option is set in both its own specific parameter and `install_switches`, the specifically named parameter takes precedence. For example, if you set an SA password in both `sa_pwd` and in `install_switches`, the `sa_pwd` parameter will be honored.

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
* `sa_pwd`: Required when :security_mode => ‘SQL’.
* `security_mode`:Specifies the security mode for SQL Server. If this parameter is not supplied, then Windows-only authentication mode is supported. Valid values are `SQL`.
* `service_ensure`: Setting this to `automatic` ensures running if stopped; `manual` sets the service to manual and takes no action on current state; `disable` stops and disables the service. Valid values are `automatic`, `manual`, `disable`.
* `source`: The drive where the ISO is mounted or expanded; can be a network share.
* `sql_svc_account`: Account for SQL Server service: Domain\User or system account.
* `sql_svc_password`: The SQL Server service password; required only for a domain account.
* `sql_sysadmin_accounts`: The Windows or SQL account(s) to provision as SQL Server system administrators.
* `install_switches`: Hash of optional installer switches for SQL Server instance setup.

  Please note that if an option is set in both its own specific parameter and `install_switches`, the specifically named parameter takes precedence. For example, if you set an SA password in both `sa_pwd` and in `install_switches`, the `sa_pwd` parameter will be honored.

For more information about installer switches and configuration, see the links below:

* [Installer Switches](https://msdn.microsoft.com/en-us/library/ms144259.aspx)
* [Configuration File](https://msdn.microsoft.com/en-us/library/dd239405.aspx)

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
* `default_fulltext_language`: Sets default fulltext language. Only applicable if `containment` => ‘PARTIAL’. Valid values are documented at [http://msdn.microsoft.com/en-us/library/ms190303.aspx](http://msdn.microsoft.com/en-us/library/ms190303.aspx). Defaults to 'us_english'.
* `default_language`: Sets default language. Only applicable if `containment` => ‘PARTIAL’. Valid values are documented at http://msdn.microsoft.com/en-us/library/ms190303.aspx. Defaults to 'us_english'.
* `nested_triggers`: Enables cascading triggers. Only applicable if `containment` => ‘PARTIAL’. Valid values are 'ON', 'OFF'. See [http://msdn.microsoft.com/en-us/library/ms178101.aspx](http://msdn.microsoft.com/en-us/library/ms178101.aspx) for complete documentation.
* `transform_noise_words`: Removes noise or stop words, such as “is”, “the”, “this”. Only applicable if `containment` => ‘PARTIAL’. Valid values are 'ON', 'OFF'.
* `two_digit_year_cutoff`: The year at which the system will treat the year as four digits instead of two. For example, if set to '1999', 1998 would be abbreviated to '98', while 2014 would be '2014'. Only applicable if `containment` => ‘PARTIAL’. Valid values are any year between 1753 and 9999. Defaults to 2049.
* `db_chaining`: Whether the database can be the source or target of a cross-database ownership chain. Only applicable if `containment` => ‘PARTIAL’. Valid values are 'ON', 'OFF'. Defaults to 'OFF'.
* `trustworthy`: Whether database modules (such as views, user-defined functions, or stored procedures) that use an impersonation context can access resources outside the database. Only applicable if `containment` => ‘PARTIAL’. Valid values are 'ON', 'OFF'. Defaults to 'OFF'.

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

#### sqlserver::sp_configure

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

##Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can’t access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

You can read the complete module contribution guide on [Contributing to the Puppet Forge](https://docs.puppetlabs.com/forge/contributing.html).
