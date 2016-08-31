# sqlserver

#### Table of contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with sqlserver](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with sqlserver](#beginning-with-sqlserver)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Install SQL Server tools and features](#install-sql-server-tools-and-features-not-specific-to-a-sql-server-instance)
    * [Create a new database](#create-a-new-database-on-an-instance-of-sql-server)
    * [Set up a new login](#set-up-a-new-login)
    * [Create a new login and a user](#create-a-new-login-and-a-user-for-a-given-database)
    * [Manage the user's permissions](#manage-the-above-users-permissions)
    * [Run custom TSQL statements](#run-custom-tsql-statements)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)

## Overview

The sqlserver module installs and manages Microsoft SQL Server 2012 and 2014 on Windows systems.

## Module description

Microsoft SQL Server is a database platform for Windows. The sqlserver module lets you use Puppet to install multiple instances of SQL Server, add SQL features and client tools, execute TSQL statements, and manage databases, users, roles, and server configuration options.

## Setup

### Setup requirements

The sqlserver module requires the following:

* Puppet Enterprise 3.7 or later.
* .NET 3.5. (Installed automatically if not present. This might require an internet connection.)
* The contents of the SQL Server ISO file, mounted or extracted either locally or on a network share.
* Windows Server 2012 or 2012 R2.

### Beginning with sqlserver

To get started with the sqlserver module, include these settings in your manifest:

~~~puppet
sqlserver_instance{ 'MSSQLSERVER':
  features              => ['SQL'],
  source                => 'E:/',
  sql_sysadmin_accounts => ['myuser'],
}
~~~

This example installs MS SQL and creates an MS SQL instance named MSSQLSERVER. It also installs the base SQL feature set (Data Quality, FullText, Replication, and SQLEngine), specifies the location of the setup.exe, and creates a new SQL-only sysadmin, 'myuser'.

A more advanced configuration, including installer switches:

~~~puppet
sqlserver_instance{ 'MSSQLSERVER':
  source                  => 'E:/',
  features                => ['SQL'],
  security_mode           => 'SQL',
  sa_pwd                  => 'p@ssw0rd!!',
  sql_sysadmin_accounts   => ['myuser'],
  install_switches        => {
    'TCPENABLED'          => 1,
    'SQLBACKUPDIR'        => 'C:\\MSSQLSERVER\\backupdir',
    'SQLTEMPDBDIR'        => 'C:\\MSSQLSERVER\\tempdbdir',
    'INSTALLSQLDATADIR'   => 'C:\\MSSQLSERVER\\datadir',
    'INSTANCEDIR'         => 'C:\\Program Files\\Microsoft SQL Server',
    'INSTALLSHAREDDIR'    => 'C:\\Program Files\\Microsoft SQL Server',
    'INSTALLSHAREDWOWDIR' => 'C:\\Program Files (x86)\\Microsoft SQL Server',
  }
}
~~~

This example creates the same MS SQL instance as shown above with additional options: security mode (requiring password to be set) and other optional install switches. This is specified using a hash syntax.

## Usage

Note: For clarification on Microsoft SQL Server terminology, please see [Microsoft SQL Server Terms](#microsoft-sql-server-terms) below.

### Install SQL Server tools and features not specific to a SQL Server instance

~~~puppet
sqlserver_features { 'Generic Features':
  source   => 'E:/',
  features => ['Tools'],
}
~~~

~~~puppet
sqlserver_features { 'Generic Features':
  source   => 'E:/',
  features => ['ADV_SSMS', 'BC', 'Conn', 'SDK', 'SSMS'],
}
~~~

### Create a new database on an instance of SQL Server

~~~puppet
sqlserver::database{ 'minviable':
  instance => 'MSSQLSERVER',
}
~~~

### Set up a new login

~~~puppet
# SQL Login
sqlserver::login{ 'vagrant':
  instance => 'MSSQLSERVER',
  password => 'Pupp3t1@',
}

# Windows Login
sqlserver::login{ 'WIN-D95P1A3V103\localAccount':
  instance   => 'MSSQLSERVER',
  login_type => 'WINDOWS_LOGIN',
}
~~~

### Create a new login and a user for a given database

~~~puppet
sqlserver::login{ 'loggingUser':
  password => 'Pupp3t1@',
}

sqlserver::user{ 'rp_logging-loggingUser':
  user     => 'loggingUser',
  database => 'rp_logging',
  require  => Sqlserver::Login['loggingUser'],
}
~~~

### Manage the above user's permissions

~~~puppet
sqlserver::user::permissions{ 'INSERT-loggingUser-On-rp_logging':
  user        => 'loggingUser',
  database    => 'rp_logging',
  permissions => 'INSERT',
  require     => Sqlserver::User['rp_logging-loggingUser'],
}

sqlserver::user::permissions{ 'Deny the Update as we should only insert':
  user        => 'loggingUser',
  database    => 'rp_logging',
  permissions => 'UPDATE',
  state       => 'DENY',
  require     => Sqlserver::User['rp_logging-loggingUser'],
}
~~~

### Run custom TSQL statements

#### Use `sqlserver_tsql` to trigger other classes or defines

~~~puppet
sqlserver_tsql{ 'Query Logging DB Status':
  instance => 'MSSQLSERVER',
  onlyif   => "IF (SELECT count(*) FROM myDb.dbo.logging_table WHERE
      message like 'FATAL%') > 1000  THROW 50000, 'Fatal Exceptions in Logging', 10",
  notify   => Exec['Too Many Fatal Errors']
}
~~~

#### Clean up regular logs with conditional checks

~~~puppet
sqlserver_tsql{ 'Cleanup Old Logs':
  instance => 'MSSQLSERVER',
  command  => "DELETE FROM myDb.dbo.logging_table WHERE log_date < '${log_max_date}'",
  onlyif   => "IF exists(SELECT * FROM myDb.dbo.logging_table WHERE log_date < '${log_max_date}')
      THROW 50000, 'need log cleanup', 10",
}
~~~

#### Always execute a statement by omitting the `onlyif` parameter

~~~puppet
sqlserver_tsql{ 'Always running':
  instance => 'MSSQLSERVER',
  command  => 'EXEC notified_executor()',
}
~~~

## Reference

### Types

#### `sqlserver_features`

Installs and configures features such as SSMS and Master Data Service.

* `ensure`: Specifies whether the managed feature(s) should exist. Valid options: 'present' and 'absent'. Default: 'present'.

* `features`: *Required.* Specifies one or more features to manage. Valid options: 'BC', 'Conn', 'SSMS', 'ADV_SSMS', 'SDK', 'IS', 'MDS', and 'Tools' (the Tools feature includes SSMS, ADV_SSMS, and Conn).

* `install_switches`: *Optional.* Passes one or more installer switches to SQL Server Setup. Please note that if an option is set in both its own specific parameter and `install_switches`, the specifically named parameter takes precedence. For example, if you set the product key in both `pid` and in `install_switches`, SQL Server honors the `pid` parameter. Valid options: an array. Default: {}.

* `is_svc_account`: *Optional.* Specifies a domain or system account to be used by Integration Services. Valid options: a string containing an existing username. Default: 'NT AUTHORITY\NETWORK SERVICE'.

* `is_svc_password`: *Required if `is_svc_account` points to a domain account. Invalid for system accounts.* Supplies the password for the Integration Services user account. Valid options: a string containing a valid password.

* `pid`: *Optional.* Supplies a product key to configure which edition of SQL Server to use. Valid options: a string containing a valid product key. Default: undef (if not specified, SQL Server runs in Evaluation mode).

* `source`: *Required.* Locates the SQL Server installer. Valid options: a string containing the path to an executable. Puppet must have permission to execute the installer.

* `windows_feature_source`: *Optional.* Specifies the location of the Windows Feature source files, which might be needed to install the .NET Framework. See https://support.microsoft.com/en-us/kb/2734782 for more information.

Please note that if an option is set in both its own specific parameter and `install_switches`, the specifically named parameter takes precedence. For example, if you set the product key in both `pid` and in `install_switches`, SQL Server honors the `pid` parameter.

For more information about installer switches and configuring SQL Server, see the links below:

* [Installer Switches](https://msdn.microsoft.com/en-us/library/ms144259.aspx)
* [Configuration File](https://msdn.microsoft.com/en-us/library/dd239405.aspx)

#### `sqlserver_instance`

Installs and configures a SQL Server instance.

* `agt_svc_account`: *Optional.* Specifies a domain or system account to be used by the SQL Server Agent service. Valid options: a string containing an existing username.

* `agt_svc_password`: *Required if `agt_svc_account` points to a domain account. Invalid for system accounts.* Supplies the password for the Agent service's user account. Valid options: a string containing a valid password.

* `as_svc_account`: *Optional.* Specifies a domain or system account to be used by Analysis Services. Valid options: a string containing an existing username.

* `as_svc_password`: *Required if `as_svc_account` is specified.* Supplies the password for the Analysis Services user account. Valid options: a string containing a valid password.

* `as_sysadmin_accounts`: *Required if your `features` array includes the value 'AS'.* Specifies one or more SQL or domain accounts to receive sysadmin status. Valid options: an array containing one or more valid usernames.

* `ensure`: Specifies whether the managed instance should exist. Valid options: 'present' and 'absent'. Default: 'present'.

* `features`: *Required.* Specifies one or more features to manage. The list of top-level features includes 'SQL', 'AS', and 'RS'. The 'SQL' feature includes the Database Engine, Replication, Full-Text, and Data Quality Services (DQS) server. Valid options: an array containing one or more of the strings 'SQL', 'SQLEngine', 'Replication', 'FullText', 'DQ', 'AS', and 'RS'.

* `install_switches`: *Optional.* Passes one or more extra installer switches to SQL Server Instance Setup. Valid options: a hash of [installer switches](https://msdn.microsoft.com/en-us/library/ms144259.aspx).

* `name`: *Optional.* Supplies a name for the instance. Valid options: a string containing a [valid instance name](https://msdn.microsoft.com/en-us/library/ms143531.aspx). Default: the title of your declared resource.

* `pid`: *Optional.* Supplies a product key to configure which edition of SQL Server to use. Valid options: a string containing a valid product key. Default: undef (if not specified, SQL Server runs in Evaluation mode).

* `rs_svc_account`: *Optional.* Specifies a domain or system account to be used by the report service. Valid options: a string; cannot include any of the following characters:

  ~~~
  '"/ \ [ ] : ; | = , + * ? < >'
  ~~~

   Default: if not specified, Setup uses the default built-in account for the current operating system (either NetworkService or LocalSystem). If you specify a domain user account, the domain must be less than 254 characters and the username must be less than 20 characters.

* `rs_svc_password`: *Required if `rs_svc_account` points to a domain account. Invalid for system accounts.* Supplies the password for the report server's user account. Valid options: a string containing a strong password (at least 8 characters, including uppercase and lowercase alphanumeric characters and at least one symbol character. Avoid words or names that might be listed in a dictionary).

* `sa_pwd`: *Required if `security_mode` is set to 'SQL'.* Sets a password for the SQL Server sa account. Valid options: a string containing a valid password.

* `security_mode`: *Optional.* Specifies a security mode for SQL Server. Valid options: 'SQL'. Default: undef (if not specified, SQL Server uses Windows authentication).

* `service_ensure`: Specifies whether the SQL Server service should be running. Valid options: 'automatic' (Puppet starts the service if it's not running), 'manual' (Puppet takes no action), and 'disable' (Puppet stops the service if it's running).

* `source`: *Required.* Locates the SQL Server installer. Valid options: a string containing the path to an executable. Puppet must have permission to execute the installer.

* `sql_svc_account`: *Optional.* Specifies a domain or system account to be used by the SQL Server service. Valid options: a string containing an existing username. Default: undef.

* `sql_svc_password`: *Required if `sql_svc_account` points to a domain account. Invalid for system accounts.* Supplies the password for the SQL Server service's user account. Valid options: a string containing a valid password.

* `sql_sysadmin_accounts`: *Required.* Specifies one or more SQL or system accounts to receive sysadmin status. Valid options: an array containing one or more valid usernames.

* `windows_feature_source`: *Optional.* Specifies the location of the Windows Feature source files, which might be needed to install the .NET Framework. See https://support.microsoft.com/en-us/kb/2734782 for more information.

Please note that if an option is set in both its own specific parameter and `install_switches`, the specifically named parameter takes precedence. For example, if you set the product key in both `pid` and in `install_switches`, SQL Server honors the `pid` parameter.

For more information about installer switches and configuring SQL Server, see the links below:

* [Installer Switches](https://msdn.microsoft.com/en-us/library/ms144259.aspx)
* [Configuration File](https://msdn.microsoft.com/en-us/library/dd239405.aspx)

#### `sqlserver_tsql`

Executes a TSQL query against a SQL Server instance.

Requires the `sqlserver::config` define for access to the parent instance.

* `command`: *Optional.* Supplies a TSQL statement to execute. Valid options: a string.

* `instance`: *Required.* Specifies the SQL Server instance on which to execute the statement. Valid options: a string containing the name of an existing instance. Default: 'MSSQLSERVER'.

* `database`: *Optional* Specifies the default database to connect to. Default: 'master'

* `onlyif`: *Optional.* Supplies a TSQL statement to execute before running the `command` statement, determining whether to move forward. If the `onlyif` statement ends with a THROW or any non-standard exit, Puppet executes the `command` statement. Valid options: a string.

### Defines

#### `sqlserver::config`

Stores credentials for Puppet to use when managing a given SQL Server instance.

* `admin_login_type`: *Optional.* Specifies the type of login used to manage to SQL Server instance. The login type affects the `admin_user` and `admin_pass` parameters which are described below. Valid options: 'SQL_LOGIN' and 'WINDOWS_LOGIN'. Default: 'SQL_LOGIN'.

- When using SQL Server based authentication - `SQL_LOGIN`

    * `admin_pass`: *Required.* Supplies the password for the specified `admin_user` account. Valid options: a string containing a valid password.

    * `admin_user`: *Required.* Specifies a login account with sysadmin rights on the server, to be used for managing the instance. Valid options: a string containing a username.

- When using Windows based authentication - `WINDOWS_LOGIN`

    * `admin_pass`: *Optional.* Valid options: undefined or an empty string (`''`).

    * `admin_user`: *Optional.* Valid options: undefined or an empty string (`''`).

* `instance_name`: *Optional.* Specifies a SQL Server instance to manage. Valid options: a string containing the name of an existing instance. Default: the title of your declared resource.

#### `sqlserver::database`

Creates and configures a database within a given SQL Server instance.

Requires the `sqlserver::config` define for access to the parent instance.

* `collation_name`: *Optional.* Specifies a dictionary on which to base the database's default sort order. Valid options: to find out what values your system supports, run the query `SELECT * FROM sys.fn_helpcollations() WHERE name LIKE 'SQL%'`. Default: undef.

* `compatibility`: *Optional.* Specifies the version(s) of SQL Server with which the database should be compatible. Valid options: a compatibility level number (e.g., 100 for SQL Server 2008 through SQL Server 2014). For a complete list of values, see the [SQL Server documentation](http://msdn.microsoft.com/en-us/library/bb510680.aspx).

* `containment`: *Optional.* Sets the database's containment type. For details on containment, see the [SQL Server documentation](http://msdn.microsoft.com/en-us/library/ff929071.aspx). Valid options: 'NONE' and 'PARTIAL' ('PARTIAL' requires the `sqlserver::sp_configure` define). Default: 'NONE'.

* `db_chaining`: *Optional.* Determines whether the managed database can be the source or target of a cross-database ownership chain. Only applicable if `containment` is set to 'PARTIAL'. Valid options: 'ON' and 'OFF'. Default: 'OFF'.

* `db_name`: *Required.* Specifies a database to manage. Valid options: a string containing the name of the database. Default: the title of your declared resource.

* `default_fulltext_language`: *Optional.* Sets the default fulltext language. Only applicable if `containment` is set to 'PARTIAL'. Valid options: see the [SQL Server documentation](http://msdn.microsoft.com/en-us/library/ms190303.aspx). Default: 'English'.

* `default_language`: *Optional.* Sets the default language. Only applicable if `containment` is set to 'PARTIAL'. Valid options: see the [SQL Server documentation](http://msdn.microsoft.com/en-us/library/ms190303.aspx). Default: 'us_english'.

* `ensure`: Specifies whether the managed database should exist. Valid options: 'present' and 'absent'. Default: 'present'.

* `filespec_filegrowth`: *Optional.* Specifies the automatic growth increment of the filespec file. Cannot be specified if `os_file_name` is set to a UNC path. This parameter is set at creation only; it is not affected by updates. Valid options: a number, with an optional suffix of 'KB', 'MB', 'GB', or 'TB', no greater than the value of `filespec_maxsize`. If you do not include a suffix, SQL Server assumes the number is in megabytes. Default: undef.

* `filespec_filename`: *Required if `filespec_name` is specified.* Specifies the operating system (physical) name of the filespec file. This parameter is set at creation only; it is not affected by updates. Valid options: a string containing an absolute path. Default: undef.

* `filespec_maxsize`: *Optional.* Specifies the maximum size to which the filespec file can grow. Cannot be specified if `os_file_name` is set to a UNC path. This parameter is set at creation only; it is not affected by updates. Valid options: a number, no greater than 2147483647, with an optional suffix of 'KB', 'MB', 'GB', or 'TB'. If you do not include a suffix, SQL Server assumes the number is in megabytes. Default: undef.

* `filespec_name`: *Required if `filespec_filename` is specified.* Specifies the logical name of the filespec object within the SQL Server instance. This parameter is set at creation only; it is not affected by updates. Valid options: a string. Must be unique to the instance. Default: undef.

* `filespec_size`: *Optional.* Specifies the size of the filespec file. This parameter is set at creation only; it is not affected by updates. Valid options: a number, no greater than 2147483647, with an optional suffix of 'KB', 'MB', 'GB', or 'TB'. If you do not include a suffix, SQL Server assumes the number is in megabytes. Default: undef.

* `filestream_directory_name`: *Optional.* Specifies a directory in which to store filestream data. You must set this option before creating a FileTable in the database. This parameter is set at creation only; it is not affected by updates. Requires the `sqlserver::sp_configure` define. Valid options: a string containing a Windows-compatible directory name. This name must be unique among all the Database_Directory names in the SQL Server instance. Uniqueness comparison is case-insensitive, regardless of SQL Server collation settings. Default: undef.

* `filestream_non_transacted_access`: *Optional.* Specifies the level of non-transactional FILESTREAM access to the database. This parameter is set at creation only; it is not affected by updates. Requires the `sqlserver::sp_configure` define. Valid options: 'OFF', 'READ_ONLY', and 'FULL'. Default: undef.

* `instance`: *Optional.* Specifies a SQL Server instance on which to manage the database. Valid options: a string containing the name of an existing instance. Default: 'MSSQLSERVER'.

* `log_filegrowth`: *Optional.* Specifies the automatic growth increment of the log file. Cannot be specified if `os_file_name` is set to a UNC path. Does not apply to a FILESTREAM filegroup. This parameter is set at creation only; it is not affected by updates. Valid options: a number with an optional suffix of 'KB', 'MB', 'GB', or 'TB', no greater than the value of `log_maxsize`. If you do not include a suffix, SQL Server assumes the number is in megabytes. Default: undef.

* `log_filename`: *Required if `log_name` is specified.* Specifies the operating system (physical) name of the log file. This parameter is set at creation only; it is not affected by updates. Valid options: a string containing an absolute path. Default: undef.

* `log_maxsize`: *Optional.* Specifies the maximum size to which the log file can grow. Cannot be specified if `os_file_name` is set to a UNC path. This parameter is set at creation only; it is not affected by updates. Valid options: a number, no greater than 2147483647, with an optional suffix of 'KB', 'MB', 'GB', or 'TB'. If you do not include a suffix, SQL Server assumes the number is in megabytes. Default: undef.

* `log_name`: *Required if `log_filename` is specified.* Specifies the logical name of the log object within SQL Server. This parameter is set at creation only; it is not affected by updates. Valid options: a string. Default: undef.

* `log_size`: *Optional.* Specifies the size of the file. This parameter is set at creation only; it is not affected by updates. Valid options: a number, no greater than 2147483647, with an optional suffix of 'KB', 'MB', 'GB', or 'TB'. If you do not include a suffix, SQL Server assumes the number is in megabytes. Default: undef.

* `nested_triggers`: *Optional.* Specifies whether to enable cascading triggers. Only applicable if `containment` is set to 'PARTIAL'. For more about nested triggers, see the [SQL Server documentation](http://msdn.microsoft.com/en-us/library/ms178101.aspx). Valid options: 'ON' and 'OFF'. Default: undef.

* `transform_noise_words`: *Optional.* Specifies whether to remove noise or stop words, such as "is", "the", "this". Only applicable if `containment` is set to 'PARTIAL'. Valid options: 'ON' and 'OFF'. Default: undef.

* `trustworthy`: *Optional.* Determines whether database modules (such as views, user-defined functions, or stored procedures) that use an impersonation context can access resources outside the database. Only applicable if `containment` is set to 'PARTIAL'. Valid options: 'ON' and 'OFF'. Default: 'OFF'.

* `two_digit_year_cutoff`: *Optional.* Sets the year at which the system will treat the year as four digits instead of two. For example, if set to '1999', 1998 is abbreviated to '98' and 2014 is abbreviated to '2014'. Only applicable if `containment` is set to 'PARTIAL'. Valid options: any year between 1753 and 9999. Default: 2049.

**For more information about these settings in SQL Server, please see:**

* [Contained Databases](http://msdn.microsoft.com/en-us/library/ff929071.aspx)
* [Create Database TSQL](http://msdn.microsoft.com/en-us/library/ms176061.aspx)
* [Alter Database TSQL](http://msdn.microsoft.com/en-us/library/ms174269.aspx)
* [System Languages](http://msdn.microsoft.com/en-us/library/ms190303.aspx)

Note that FILESTREAM usage might require some manual configuration of SQL Server. Please see [Enable and Configure FILESTREAM](http://msdn.microsoft.com/en-us/library/cc645923.aspx) for details.

#### `sqlserver::login`

Requires the `sqlserver::config` define.

* `check_expiration`: *Optional.* Specifies whether SQL Server should prompt the user to change their password if it has expired. Only applicable if `login_type` is set to 'SQL_LOGIN'. Valid options: 'true' and 'false'. Default: 'false'.

* `check_policy`: *Optional.* Specifies whether to enforce the password policy. Only applicable if `login_type` is set to 'SQL_LOGIN'. Valid options: 'true' and 'false'. Default: 'true'.

* `default_database`: *Optional.* Specifies a database for the login to connect to by default. Valid options: a string containing the name of an existing database. Default: 'master'.

* `default_language`: *Optional.* Specifies a default language. Valid options: see the [SQL Server documentation](http://msdn.microsoft.com/en-us/library/ms190303.aspx). Default: 'us_english'.

* `disabled`: *Optional.* Specifies whether the managed login should be disabled. Valid options: 'true' and 'false'. Default: 'false'.

* `ensure`: Specifies whether the managed login should exist. Valid options: 'present' and 'absent'. Default: 'present'.

* `instance`: *Optional.* Specifies a SQL Server instance on which to manage the login. Valid options: a string containing the name of an existing instance. Default: 'MSSQLSERVER'.

* `login`: *Required.* Specifies a Windows or SQL login to manage. Valid options: a string containing an existing login.

* `login_type`: *Optional.* Specifies the type of login to use. Valid options: 'SQL_LOGIN' and 'WINDOWS_LOGIN'. Default: 'SQL_LOGIN'.

* `password`: *Required if `login_type` is set to 'SQL_LOGIN'.* Sets a password for the managed login. Valid options: a string.

* `svrroles`: *Optional.* Assigns one or more pre-installed server roles to the login. Valid options: a hash of `permission => value` pairs, where a value of 0 means disabled and a value of 1 means enabled. For example, `{'diskadmin' => 1, 'dbcreator' => 1, 'sysadmin' => 0}`. For a complete list of valid permissions, see the [SQL Server documentation](http://msdn.microsoft.com/en-us/library/ms188659.aspx).

**For more information about these settings in SQL Server, please see:**

* [Server Role Members](http://msdn.microsoft.com/en-us/library/ms186320.aspx)
* [Create Login](http://technet.microsoft.com/en-us/library/ms189751.aspx)
* [Alter Login](http://technet.microsoft.com/en-us/library/ms189828.aspx)

#### `sqlserver::login::permissions`

Configures the permissions associated with a given login account.

* `instance`: *Optional.* Specifies a SQL Server instance on which to manage the permissions. Valid options: a string containing the name of an existing instance. Default: 'MSSQLSERVER'.

* `login`: *Required.* Specifies a SQL or Windows login to manage. Valid options: a string containing an existing login.

* `permissions`: *Required.* Specifies one or more permissions to manage. Valid options: a string or an array of strings, where each string contains a [SQL Server permissions](https://technet.microsoft.com/en-us/library/ms191291%28v=sql.105%29.aspx) (e.g., 'SELECT', 'INSERT', 'UPDATE', or 'DELETE').

* `state`: *Optional.* Determines the state of the specified permissions. Valid options: 'GRANT', 'DENY', and 'REVOKE'. If set to 'REVOKE', Puppet removes any explicit statements of these permissions and falls back on inherited levels. Default: 'GRANT'.

* `with_grant_option`: *Optional.* Determines whether the account can grant these permissions to others. Valid options: 'true' and 'false'. Default: 'false'.

#### `sqlserver::user`

Creates and configures a user account within a given database.

Requires the `sqlserver::config` define for access to the parent instance.

* `database`: *Required.* Specifies the database in which to manage the user. Valid options: a string containing the name of an existing database.

* `default_schema`: *Optional.* Specifies a SQL schema or namespace for the user to connect to by default. Valid options: a string. Default: 'dbo' unless changed at the server level.

* `ensure`: Specifies whether the managed user should exist. Valid options: 'present' and 'absent'. Default: 'present'.

* `instance`: *Optional.* Specifies a SQL Server instance on which to manage the user. Valid options: a string containing the name of an existing instance. Default: 'MSSQLSERVER'.

* `login`: *Optional.* Associates the user with a login. Valid options: a string containing an existing login. Default: undef (if not specified, SQL Server assumes the username and login are the same).

* `password`: *Optional.* Assigns a password to the user. Only valid if the database's `containment` parameter is set to 'PARTIAL'. Valid options: a string containing a valid password.

* `user`: *Required.* Specifies a user to manage. Valid options: a string containing a username. Default: the title of your declared resource.

#### `sqlserver::user::permissions`

Configures the permissions associated with a user account within a given database.

Requires the `sqlserver::config` define for access to the parent instance.

* `database`: *Required.* Specifies the database in which to manage the user's permissions. Valid options: a string containing the name of an existing database.

* `instance`: *Optional.* Specifies the SQL Server instance on which the user and database exist. Valid options: a string containing the name of an existing instance. Default: 'MSSQLSERVER'.

* `permissions`: *Required.* Specifies one or more permissions to manage. Valid options: an array containing one or more [SQL Server permissions](https://technet.microsoft.com/en-us/library/ms191291%28v=sql.105%29.aspx) formatted as strings (e.g., `['SELECT', 'INSERT', 'UPDATE', 'DELETE']`).

* `state`: *Optional.* Determines the state of the specified permissions. Valid options: 'GRANT', 'DENY', and 'REVOKE'. If set to 'REVOKE', Puppet removes any explicit statements of these permissions and falls back on inherited levels. Default: 'GRANT'.

* `user`: *Required.* Specifies which user's permissions to manage. Valid options: a string containing a username. Default: the title of your declared resource.

* `with_grant_option`: *Optional.* Determines whether the affected user can grant these permissions to others. Valid options: 'true' and 'false'. Default: 'false'.

**For more information about these settings and permissions in SQL Server, please see:**

* [Permissions (Database Engine)](https://msdn.microsoft.com/en-us/library/ms191291.aspx)
* [Grant Database Permissions](https://msdn.microsoft.com/en-us/library/ms178569.aspx)

#### `sqlserver::role`

Creates and configures a server-wide or database-specific role.

Requires the `sqlserver::config` define for access to the parent instance.

* `authorization`: *Optional.* Sets the role's owner. Valid options: a string containing an existing login or username. Default: the value of `user` in the corresponding `sqlserver::config` resource.

* `database`: *Optional.* Specifies the database on which to create the role. Only valid if `type` is set to 'DATABASE'. Valid options: a string containing the name of an existing database. Default: 'master'.

* `ensure`: Specifies whether the managed role should exist. Valid options: 'absent' and 'present'. Default: 'present'.

* `instance`: *Optional.* Specifies a SQL Server instance on which to manage the role. Valid options: a string containing the name of an existing instance. Default: 'MSSQLSERVER'.

* `members`: *Optional.* Assigns one or more members to the role. Valid options: an array of one or more logins and/or usernames. Default: {}.

* `members_purge`: *Optional.* Specifies whether to drop any existing members of the role that are not explicitly included in the `members` parameter. **Use with caution.** If set to 'true' and `members` is an empty array, Puppet drops all members from the role. Valid options: 'true' and 'false'. Default: 'false'.

* `permissions`: *Required.* Associates one or more permissions with the role. Valid options: a hash of one or more key => value pairs, where each key is the desired permission state and each value is an array of strings specifying the permissions to be managed.

  **Valid hash keys:**
  * 'GRANT'
  * 'GRANT_WITH_OPTION' (lets the user grant this permission to others)
  * 'DENY'
  * 'REVOKE' (removes any explicit statements of this permission and falls back on inherited levels)

  **Valid hash values:** An array of one or more strings containing [SQL Server permissions](https://technet.microsoft.com/en-us/library/ms191291%28v=sql.105%29.aspx).

  **Example:** `{'GRANT' => ['CONNECT', 'CREATE ANY DATABASE'] }`

* `role`: *Optional.* Sets the role's name. Valid options: a string. Must be unique to the instance. Default: the title of your declared resource.

* `type`: *Optional.* Specifies the context in which to create the role. Valid options: 'SERVER' and 'DATABASE'. Default: 'SERVER'.

#### `sqlserver::role::permissions`

Configures the permissions associated with a given role.

Requires the `sqlserver::config` define for access to the parent instance.

* `database`: *Optional.* Specifies the database in which the role exists. Only valid if `type` is set to 'DATABASE'. Valid options: a string containing the name of an existing database. Default: 'master'.

* `instance`: *Optional.* Specifies a SQL Server instance on which to manage the role. Valid options: a string containing the name of an existing instance. Default: 'MSSQLSERVER'.

* `permissions`: *Required.* Specifies one or more permissions to manage. Valid options: an array containing one or more [SQL Server permissions](https://technet.microsoft.com/en-us/library/ms191291%28v=sql.105%29.aspx) (e.g., 'SELECT', 'INSERT', 'UPDATE', and 'DELETE').

* `role`: *Required.* Specifies which role's permissions to manage. Valid options: a string containing the name of an existing role.

* `state`: *Optional.* Determines the state of the specified permission. Valid options: 'GRANT', 'DENY', and 'REVOKE'. If set to 'REVOKE', Puppet removes any explicit statements of these permissions and falls back on inherited levels. Default: 'GRANT'.

* `type`: *Optional.* Specifies the permission context in which to create the role. Valid options: 'SERVER' and 'DATABASE'. Default: 'SERVER'.

* `with_grant_option`: *Optional.* Determines whether role members can grant these permissions to others. Valid options: 'true' and 'false' ('true' valid only if `state` is set to 'GRANT'). Default: 'false'.

#### `sqlserver::sp_configure`

Updates and reconfigures SQL Server options using the sp_configure function. Required for partial containment or filestream functionality.

Requires the `sqlserver::config` define for access to the parent instance.

* `config_name`: *Optional.* Specifies an option to manage in sys.configurations. Valid options: a string containing the config name. Default: the title of your declared resource.

* `instance`: *Optional.* Specifies a SQL Server instance on which to manage the option. Valid options: a string containing the name of an existing instance. Default: 'MSSQLSERVER'.

* `reconfigure`: *Optional.* Specifies whether to run RECONFIGURE after updating the option. Valid options: 'true' and 'false'. Default: 'true'.

* `restart`: *Optional.* Specifies whether to notify the SQL Server service to restart after updating the option. Valid options: 'true' and 'false'. Default: 'false'.

* `value`: *Required.* Supplies a value for the specified option. Valid options: an integer.

* `with_override`: *Optional.* Disables configuration value checking when updating the option. Valid only if `reconfigure` is set to 'true'. Valid options: 'true' and 'false'. Default: 'false'.

**For more information about these settings in SQL Server, please see:**

* [Reconfigure](http://msdn.microsoft.com/en-us/library/ms176069.aspx)
* [Server Configuration Options](http://msdn.microsoft.com/en-us/library/ms189631.aspx)

### Microsoft SQL Server Terms

Terminology differs somewhat between various database systems; please refer to this list of terms for clarification.

* **Database:** a collection of information organized into related tables of data and definitions of data objects.
* **Instance:** an installed and running database service.
* **Login:** a server-level account with permissions to one or more databases.
* **Role:** a database-level or server-level permissions group.
* **User:** a database-level account, typically mapped to a login.

## Limitations

This module is available only for Windows Server 2012 or 2012 R2, and works with Puppet Enterprise 3.7 and later.

## Development

This module was built by Puppet Inc. specifically for use with Puppet Enterprise (PE).

If you run into an issue with this module, or if you would like to request a feature, please [file a ticket](https://tickets.puppet.com/browse/MODULES/).

If you have problems getting this module up and running, please [contact Support](https://puppet.com/support-services/customer-support).
