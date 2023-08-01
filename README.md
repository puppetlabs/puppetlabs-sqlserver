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

The sqlserver module installs and manages Microsoft SQL Server 2012, 2014, 2016, 2017, 2019 and 2022 on Windows systems.

## Module Description

Microsoft SQL Server is a database platform for Windows. The sqlserver module lets you use Puppet to install multiple instances of SQL Server, add SQL features and client tools, execute TSQL statements, and manage databases, users, roles, and server configuration options.

## Setup

### Setup Requirements

The sqlserver module requires the following:

* .NET 3.5. (Installed automatically if not present. This might require an internet connection.)
* The contents of the SQL Server ISO file, mounted or extracted either locally or on a network share.
* Windows Server 2012+.

### Beginning with sqlserver

To get started with the sqlserver module, include in your manifest:

```puppet
sqlserver_instance{ 'MSSQLSERVER':
    features                => ['SQL'],
    source                  => 'E:/',
    sql_sysadmin_accounts   => ['myuser'],
}
```

This example installs MS SQL and creates an MS SQL instance named MSSQLSERVER. It also installs the base SQL feature set (Data Quality, FullText, Replication, and SQLEngine), specifies the location of the setup.exe, and creates a new SQL-only sysadmin, 'myuser'.

A more advanced configuration, including installer switches:

```puppet
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
```

This example creates the same MS SQL instance as shown above with additional options: security mode (requiring password to be set) and other optional install switches. This is specified using a hash syntax.

## Usage

**Note**: For clarification on Microsoft SQL Server terminology, please see [Microsoft SQL Server Terms](#microsoft-sql-server-terms) below.

### Install SQL Server tools and features not specific to a SQL Server instance

```puppet
sqlserver_features { 'Generic Features':
  source   => 'E:/',
  features => ['BC', 'Conn', 'SDK'],
}
```

### Create a new database on an instance of SQL Server

```puppet
sqlserver::database{ 'minviable':
  instance => 'MSSQLSERVER',
}
```

### Set up a new login

```puppet
SQL Login
sqlserver::login{ 'vagrant':
  instance => 'MSSQLSERVER',
  password => 'Pupp3t1@',
}

# Windows Login
sqlserver::login{ 'WIN-D95P1A3V103\localAccount':
  instance   => 'MSSQLSERVER',
  login_type => 'WINDOWS_LOGIN',
}
```

### Create a new login and a user for a given database

```puppet
sqlserver::login{ 'loggingUser':
  password => 'Pupp3t1@',
}

sqlserver::user{ 'rp_logging-loggingUser':
  user     => 'loggingUser',
  database => 'rp_logging',
  require  => Sqlserver::Login['loggingUser'],
}
```

### Manage the above user's permissions

```puppet
sqlserver::user::permissions{'INSERT-loggingUser-On-rp_logging':
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
```

### Run custom TSQL statements

#### Use `sqlserver_tsql` to trigger other classes or defined types

```puppet
sqlserver_tsql{ 'Query Logging DB Status':
  instance => 'MSSQLSERVER',
  onlyif   => "IF (SELECT count(*) FROM myDb.dbo.logging_table WHERE
      message like 'FATAL%') > 1000  THROW 50000, 'Fatal Exceptions in Logging', 10",
  notify   => Exec['Too Many Fatal Errors']
}
```

#### Clean up regular logs with conditional checks

```puppet
sqlserver_tsql{ 'Cleanup Old Logs':
  instance => 'MSSQLSERVER',
  command  => "DELETE FROM myDb.dbo.logging_table WHERE log_date < '${log_max_date}'",
  onlyif   => "IF exists(SELECT * FROM myDb.dbo.logging_table WHERE log_date < '${log_max_date}')
      THROW 50000, 'need log cleanup', 10",
}
```

#### If you want your statement to always execute, leave out the `onlyif` parameter

```puppet
sqlserver_tsql{ 'Always running':
  instance => 'MSSQLSERVER',
  command  => 'EXEC notified_executor()',
}
```

### Advanced example

This advanced example:

* Installs the basic SQL Server Engine from installation media mounted at 'D:\' with TCP Enabled and various directories set.

* Uses only Windows-based authentication and installs with only the user that Puppet is executing as. Note that the 'sql_sysadmin_accounts' is only applicable during the instance installation and is not actively enforced.

* Creates a `sqlserver::config` resource, which is used in later resources to connect to the newly created instance. As we support only Windows-based authentication, a username and password is not required.

* Creates a local group called 'DB Administrators' and ensures that it is SQL System Administrator (sysadmin role); also creates the account that Puppet uses to install and manage the instance.

* Ensures that the advanced options for `sp_configure` are enabled, so that Puppet can manage the `max memory` setting for the instance.

* Ensure that the `max memory` (MB) configuration item is set to 2048 megabytes.

```puppet
$sourceloc = 'D:/'

# Install a SQL Server default instance
sqlserver_instance{'MSSQLSERVER':
  source                => $sourceloc,
  features              => ['SQLEngine'],
  sql_sysadmin_accounts => [$facts['id']],
  install_switches      => {
    'TCPENABLED'          => 1,
    'SQLBACKUPDIR'        => 'C:\\MSSQLSERVER\\backupdir',
    'SQLTEMPDBDIR'        => 'C:\\MSSQLSERVER\\tempdbdir',
    'INSTALLSQLDATADIR'   => 'C:\\MSSQLSERVER\\datadir',
    'INSTANCEDIR'         => 'C:\\Program Files\\Microsoft SQL Server',
    'INSTALLSHAREDDIR'    => 'C:\\Program Files\\Microsoft SQL Server',
    'INSTALLSHAREDWOWDIR' => 'C:\\Program Files (x86)\\Microsoft SQL Server'
  }
}

# Resource to connect to the DB instance
sqlserver::config { 'MSSQLSERVER':
  admin_login_type => 'WINDOWS_LOGIN'
}

# Enforce SQL Server Administrators
$local_dba_group_name = 'DB Administrators'
$local_dba_group_netbios_name = "${facts['hostname']}\\DB Administrators"

group { $local_dba_group_name:
  ensure => present
}

-> sqlserver::login { $local_dba_group_netbios_name :
  login_type  => 'WINDOWS_LOGIN',
}

-> sqlserver::role { 'sysadmin':
  ensure   => 'present',
  instance => 'MSSQLSERVER',
  type     => 'SERVER',
  members  => [$local_dba_group_netbios_name, $facts['id']],
}

# Enforce memory consumption
sqlserver_tsql {'check advanced sp_configure':
  command => 'EXEC sp_configure \'show advanced option\', \'1\'; RECONFIGURE;',
  onlyif => 'sp_configure @configname=\'max server memory (MB)\'',
  instance => 'MSSQLSERVER'
}

-> sqlserver::sp_configure { 'MSSQLSERVER-max memory':
  config_name => 'max server memory (MB)',
  instance => 'MSSQLSERVER',
  reconfigure => true,
  restart => true,
  value => 2048
}
```
*Note:*
$facts['hostnane'] is only suitable for building login names for local machine logins. For building domain logins you will need the domain name instead. $facts['domain'] returns the full domain name which will usually not be what you need. Try instead:

```puppet
$netbios_name = split($facts['domain'],'\.')[0]

$dba_group_netbios_name = "${netbios_name}\\DB Administrators"

sqlserver::role { 'sysadmin':
  ensure   => 'present',
  instance => 'MSSQLSERVER',
  type     => 'SERVER',
  members  => [$dba_group_netbios_name, $facts['id']],
}
```

## Reference

For information on the classes and types, see the [REFERENCE.md](https://github.com/puppetlabs/puppetlabs-sqlserver/blob/main/REFERENCE.md)

## Limitations

SQL 2017, 2019 and 2022 detection support has been added. This support is limited to functionality already present for other versions.

The MSOLEDBSQL driver is now required to use this module. You can use this chocolatey [package](https://community.chocolatey.org/packages/msoledbsql) for installation. but it must version 18.x or earlier. (v19+ is not currently supported)

This module can manage only a single version of SQL Server on a given host (one and only one of SQL Server 2012, 2014, 2016, 2017, 2019 or 2022). The module is able to manage multiple SQL Server instances of the same version.

This module cannot manage the SQL Server Native Client SDK (also known as SNAC_SDK). The SQL Server installation media can install the SDK, but it is not able to uninstall the SDK. Note that the 'sqlserver_features' fact detects the presence of the SDK.

In SQL Server 2016 and newer, Microsoft separated the installation of SQL Server Management Studio (SSMS) from the installation of the SQL Server engine and other features. SSMS now has its own installer and can be [installed and managed via Chocolatey](https://chocolatey.org/packages/sql-server-management-studio). As such, specifying SSMS in the `sqlserver` as a feature to install no longer works with SQL Server 2016 and newer. Instead, use `package` resources with the [Chocolatey provider](https://forge.puppet.com/puppetlabs/chocolatey) to manage SSMS installation.

## Development

This module was built by Puppet specifically for use with Puppet Enterprise (PE).

If you run into an issue with this module, or if you would like to request a feature, please [file a ticket](https://tickets.puppet.com/browse/MODULES/).

If you have problems getting this module up and running, please [contact Support](https://puppet.com/support-services/customer-support).

If you would like to contribute to this module, please follow the rules in the [CONTRIBUTING.md](https://github.com/puppetlabs/puppetlabs-sqlserver/blob/master/CONTRIBUTING.md). For more information, see our [module contribution guide.](https://puppet.com/docs/puppet/latest/contributing.html)
