## 2017-02-15 - Supported Release 1.1.5

### Summary

- Small release with several bug fixes and a minor feature.

#### Features

- Obfuscate passwords in logs if sqlserver_instance raises an error ([MODULES-4255](https://tickets.puppet.com/browse/MODULES-4255)).

#### Bug Fixes

- Fix issues with installing .Net 3.5 in acceptance tests
- Fix various issues with test environment in AppVeyor, Travis CI and Jenkins
- Fix documentation for localization

## 2016-08-31 - Supported Release 1.1.4

### Summary

- Small release with several bug fixes and a minor feature.

#### Features

- Add `windows_feature_source` parameter to the `sqlserver_instance` and `sqlserver_features` resources. This specifies the location of the Windows Feature source files, which might be needed to install the .NET Framework. See https://support.microsoft.com/en-us/kb/2734782 for more information ([MODULES-3202](https://tickets.puppet.com/browse/MODULES-3202)).

#### Bug Fixes

- Fix issues when adding multiple SYSADMIN role accounts on instance creation ([MODULES-3427](https://tickets.puppet.com/browse/MODULES-3427)).
- Fix issues when creating and deleting Windows base logins ([MODULES-3256](https://tickets.puppet.com/browse/MODULES-3256)).
- Fix errors when deleting MS SQL Server logins ([MODULES-2323](https://tickets.puppet.com/browse/MODULES-2323)) and databases ([MODULES-2554](https://tickets.puppet.com/browse/MODULES-2554)).
- Refactor acceptance tests for `sqlserver::login` resource ([MODULES-3256](https://tickets.puppet.com/browse/MODULES-3256)).
- Fix issues when modifying server roles for an existing login ([MODULES-3083](https://tickets.puppet.com/browse/MODULES-3083)).
- Fix issues when modifying an existing Windows user login ([MODULES-3752](https://tickets.puppet.com/browse/MODULES-3752)).

## 2016-07-12 - Supported Release 1.1.3

### Summary

- Small release with several bug fixes and minor features.
- Update the supported Puppet version ranges.

#### Features

- Update documentation with a more advanced SQL example.
- Add Windows Based Authentication for `sqlserver::config`. Modifies the `sqlserver::config` class with an additional property called `login_type` which can be either `SQL_LOGIN` or `WINDOWS_LOGIN`, with a default of `SQL_LOGIN`.

#### Bug Fixes

- Fix Role Name Collisions. This fix introduces the database name into the title created for the `sqlserver_tsql` statements so that it is unique.
- Minor refactoring of code which is not used or makes code path more obvious.
- Fix TSQL error propagation. Introduce a minor refactor so that the `returns` property captures errors properly from TSQL executions.
- Emit debug output on failed `onlyif` TSQL. Previously, there was no way of getting the log output from SQL Server when executing TSQL during an `onlyif`.

## 2016-04-11 - Supported Release 1.1.2

### Summary

Small release to update supported Puppet version ranges.

## 2015-12-08 - Supported Release 1.1.1

### Summary

Small release to support newer PE versions.

## 2015-09-08 - Supported Release 1.1.0

### Summary

User, Roles, and Login, as well as the permissions associated with each, are now available.

#### Features

- `sqlserver_instance` and `sqlserver_features` have new parameter `install_switches`, which takes a hash of install switches and writes them to a temporary configuration file for the install process.
- Add define for permissions for Users, Roles, and Logins.
- `sqlserver::config` no longer writes a file to the sytem.
- New `sqlserver_tsql` provider available to execute custom scripts.
- Remove dependency on 'sqlcmd.exe'.
- Performance discovery improvements.
- Remove dependency for ACL modules.

#### Bug Fixes

- Munge values for instance names to always be uppercase when comparing.
- Change the way we look up logins to use sys.server_principals instead of a function that might not report correctly.
- Fix issue with `collation_name` and databases where the variable was not named properly, causing it to never be set.

## 2014-12-08 - 1.0.0

Initial release.
