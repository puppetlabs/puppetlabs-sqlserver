# mssql

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with mssql](#setup)
    * [What mssql affects](#what-mssql-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with mssql](#beginning-with-mssql)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

The mssql module installs and manages MS SQL Server 2012 and 2014 on Windows systems. 

##Module Description
 
The mssql module adds defined types to install and manage MS SQL Server 2012 and 2014 on Windows Server 2012. The module can install SQL Server clients, multiple instances, and SQL features, as well as create and manage new databases and logins. 

##Setup

###What mssql affects

This module requires .NET 3.5 and installs it if it's not already on your system. This might require an internet connection.

###Setup Requirements 

The mssql module requires the following:

* Puppet Enterprise 3.7 or later
* Puppet Supported `acl` [module](https://forge.puppetlabs.com/puppetlabs/acl)
* .NET 3.5
* ISO, mounted or expanded either locally or on a network share
* Windows Server 2012 or 2012R2
	
###Beginning with mssql

To get started with the mssql module, include these settings in your manifest: 

```
mssql_instance{'MSSQLSERVER':
    features                => ['SQL'],
    source                  => 'E:/',
    sql_sysadmin_accounts   => ['myuser'],
}
```

This manifest installs MS SQL and creates an MS SQL instance named MSSQLSERVER. It installs the base SQL feature set (Data Quality, FullText, Replication, and SQLEngine), specifies the location of the setup.exe, and creates a new SQL-only sysadmin, 'myuser'.

##Usage

###To install SQL Server tools and features not specific to a database instance:

```
mssql_features { 'Generic Features':
	source		=> 'E:/',
	features 	=> ['Tools'],
}
```

```
mssql_features { 'Generic Features':
	source		=> 'E:/',
	features 	=> ['ADV_SSMS', 'BC', 'Conn', 'SDK', 'SSMS'],
}
```

###To create a new database in an instance:

```
mssql::database{ 'minviable':
    instance => ‘MSSQLSERVER’,
}
```

###To set up a new login: 

```
SQL Login
mssql::login{'vagrant':
	instance => 'MSSQLSERVER',
	password => 'Pupp3t1@',
}

Windows Login 
mssql::login{'WIN-D95P1A3V103\localAccount':
	instance 	=> 'MSSQLSERVER',
	login_type 	=> 'WINDOWS_LOGIN',
}
```

##Reference

### Types

#### mssql_features

* `ensure`: Ensures that the resource is present. Valid values are 'present', 'absent'.
* `features`: Specifies features to install, uninstall, or upgrade. The list of top-level features include SQL, AS, RS, IS, MDS, and Tools. The Tools feature will install Management Tools, Books online components, SQL Server Data Tools, and other shared components. Valid values are 'Tools', 'BC', 'BOL', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS'.
* `is_svc_account`: Either domain user name or system account. Defaults to 'NT AUTHORITY\NETWORK SERVICE'.
* `is_svc_password`: Password for domain user.
* `name`: 
* `pid`: Specify the SQL Server product key to configure which edition you would like to use.
* `provider`: The specific backend to use for this `mssql_features` resource. You seldom need to specify this---Puppet will usually discover the appropriate provider for your platform. Available providers are: `mssql`, `source`.
  
#### mssql_instance

* `agt_svc_account`: Either domain user name or system account.
* `agt_svc_password`: Password for domain user name. Not required for system account.
* `as_svc_account`: The account used by the Analysis Services service.
* `as_svc_password`: The password for the Analysis Services service account.
* `as_sysadmin_accounts`: Specifies the list of administrator accounts to provision.
* `ensure`: Ensure whether the resource is present. Valid values are `present`, `absent`.
* `features`: Specifies features to install, uninstall, or upgrade. The list of top-level features include SQL, AS, RS, IS, MDS, and Tools. The SQL feature installs the Database Engine, Replication, Full-Text, and Data Quality Services (DQS) server. The Tools feature installs Management Tools, Books online components, SQL Server Data Tools, and other shared components. Valid values are 'SQL', 'SQLEngine', 'Replication', 'FullText', 'DQ', 'AS', 'RS', 'MDS'.
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

### Defined Types

#### `mssql::config`: Stores the config file that allows Puppet to access and modify the instance. 
* `instance_name`: The instance name you want to manage.  Defaults to the $title.
* `admin_user`: The SQL login with sysadmin rights on the server, can only be login of SQL_Login type. 
* `admin_password`: The password to access the server to be managed.

```
mssql::config{'MSSQLSERVER':
  admin_user     => 'sa',
  admin_password => 'PuppetP@ssword1',
  }
```  

#### `mssql::database`: Creates, destroys, or updates databases, but does not move or modify files. Requires defined type `mssql::config` for the instance in which you want the database created.
* `db_name`: The name of the database you want to manage. Accepts a string.
* `instance`: The name of the instance to connect to. Instance names must be strings no longer than 16 characters.
* `ensure`: Ensures that the resource is present. Valid values are 'present', 'absent'. Defaults to 'present'.
* `compatibility`: Numeric representation of the SQL Server version with which the database should be compatible. For example, 100 = SQL Server 2008 through SQL Server 2012.  For a complete list of values, refer to [http://msdn.microsoft.com/en-us/library/bb510680.aspx](http://msdn.microsoft.com/en-us/library/bb510680.aspx).
* `collation_name`: Modifies dictionary default sort rules for the datatbase. Defaults to 'Latin1_General'. To find out what other values your system supports, run the query `SELECT * FROM sys.fn_helpcollations() WHERE name LIKE 'SQL%'`.
* `filestream_non_transacted_access`: Specifies the level of non-transactional FILESTREAM access to the database. This parameter is affected only at creation; updates will not change this setting. Valid values are 'OFF', 'READ_ONLY', 'FULL'.  
* `filestream_directory_name`: Accepts a Windows-compatible directory name. This name should be unique among all the Database_Directory names in the SQL Server instance. Uniqueness comparison is case-insensitive, regardless of SQL Server collation settings. This option should be set before creating a FileTable in this database. This parameter is affected only at creation; updates will not change this setting. 
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
* `containment`: Defaults to 'NONE'.  Other possible values are 'PARTIAL'; see [http://msdn.microsoft.com/en-us/library/ff929071.aspx](http://msdn.microsoft.com/en-us/library/ff929071.aspx) for complete documentation about containment.
* `default_fulltext_language`: Sets default fulltext language. Only applicable if `containment` => ‘PARTIAL’. Valid values are documented at [http://msdn.microsoft.com/en-us/library/ms190303.aspx](http://msdn.microsoft.com/en-us/library/ms190303.aspx). Defaults to 'us_english'.
* `default_language`: Sets default language. Only applicable if `containment` => ‘PARTIAL’. Valid values are documented at http://msdn.microsoft.com/en-us/library/ms190303.aspx. Defaults to 'us_english'.
* `nested_triggers`: Enables cascading triggers. Only applicable if `containment` => ‘PARTIAL’. Valid values are 'ON', 'OFF'. See [http://msdn.microsoft.com/en-us/library/ms178101.aspx](http://msdn.microsoft.com/en-us/library/ms178101.aspx) for complete documentation.
* `transform_noise_words`: Removes noise or stop words, such as “is”, “the”, “this”. Only applicable if `containment` => ‘PARTIAL’. Valid values are 'ON', 'OFF'. 
* `two_digit_year_cutoff`: The year at which the system will treat the year as four digits instead of two. For example, if set to '1999', 1998 would be abbreviated to '98', while 2014 would be '2014'. Only applicable if `containment` => ‘PARTIAL’. Valid values are any year between 1753 and 9999. Defaults to 2049.
* `db_chaining`: Whether the database can be the source or target of a cross-database ownership chain. Only applicable if `containment` => ‘PARTIAL’. Valid values are 'ON', 'OFF'. Defaults to 'OFF'.
* `trustworthy`: Whether database modules (such as views, user-defined functions, or stored procedures) that use an impersonation context can access resources outside the database. Only applicable if `containment` => ‘PARTIAL’. Valid values are 'ON', 'OFF'. Defaults to 'OFF'.

**For more information about Microsoft SQL Server, please see:**
* [Contained Databases](http://msdn.microsoft.com/en-us/library/ff929071.aspx)
* [Create Database TSQL](http://msdn.microsoft.com/en-us/library/ms176061.aspx)
* [Alter Database TSQL](http://msdn.microsoft.com/en-us/library/ms174269.aspx)
* [System Languages](http://msdn.microsoft.com/en-us/library/ms190303.aspx)

#### `mssql::login`: Requires defined type `mssql::config` in order to execute against the SQL Server instance
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
* `is_disabled`: Valid values are 'true', 'false'. Defaults to 'false'. 

**For more information about Microsoft SQL Server, please see:**
* [Server Role Members](http://msdn.microsoft.com/en-us/library/ms186320.aspx)
* [Create Login](http://technet.microsoft.com/en-us/library/ms189751.aspx) 
* [Alter Login](http://technet.microsoft.com/en-us/library/ms189828.aspx)


##Limitations

This module is available only for Puppet Enterprise 3.7 and later. 

##Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can’t access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

You can read the complete module contribution guide on the [Puppet Labs wiki](http://projects.puppetlabs.com/projects/module-site/wiki/Module_contributing).
