## Unreleased

### Summary

#### Fixed
- Ensure that multiple accounts can be included in SQLSYSADMINACCOUNTS when installing SQL Server ([MODULES-6356](https://tickets.puppetlabs.com/browse/MODULES-6356))

## 2017-12-8 - Supported Release 2.1.0

### Summary
Add support for detecting and installing SQL Server 2017.
This release does not add any new SQL 2017 specific features.

#### Added

- Add support for installing and managing SQL 2017 instances. ([MODULES-6168](https://tickets.puppetlabs.com/browse/MODULES-6168))
- Update documentation to reflect change that adds 2017 support. ([MODULES-6244](https://tickets.puppetlabs.com/browse/MODULES-6244))

## 2017-12-5 - Supported Release 2.0.2

### Summary
Small release with critical bug fix for sql instance install idempotency.

#### Fixed

- Fix bug where Puppet will not detect existing sql instances properly
attempt to reinstall an instance that already exists ([MODULES-6022](https://tickets.puppetlabs.com/browse/MODULES-6022))

## 2017-11-15 - Supported Release 2.0.1

### Summary
Small release with bug fixes and documentation updates.

#### Fixed

- Allow connections over TLS 1.1+ by replacing OLEDB driver with SQL Native Client ([MODULES-5693](https://tickets.puppetlabs.com/browse/MODULES-5693))
- Ensure instances without SQL Engine are discoverable ([MODULES-5566](https://tickets.puppetlabs.com/browse/MODULES-5566))
- Updated documentation to include 2016 as a supported version of SQL Server

## 2017-08-10 - Supported Release 2.0.0

### Summary

This major release adds support for Microsoft SQL Server 2016

#### Added

- Added more detailed examples to the README
- Updated with Puppet 4 data types ([MODULES-5126](https://tickets.puppet.com/browse/MODULES-5126))
- Added parameters to manage PolyBase ([MODULES-5070](https://tickets.puppet.com/browse/MODULES-5070))
- Added support for Windows Server 2016
- Updated metadata for Puppet 5 ([MODULES-5144](https://tickets.puppet.com/browse/MODULES-5144))
- Added test tiering and test mode switcher ([FM-5062](https://tickets.puppet.com/browse/FM-5062), [FM-6141](https://tickets.puppet.com/browse/FM-6141))

#### Deprecated

- Deprecated the use of `Tools` and `SQL` as installation features ([MODULES-4257](https://tickets.puppet.com/browse/MODULES-4257))

#### Removed

- Removed unsupported Puppet versions from metadata ([MODULES-4842](https://tickets.puppet.com/browse/MODULES-4842))
- Removed support for Stdlib on unsupported Puppet versions, (Stdlib versions less than 4.13.0)

#### Fixed

- Make .Net installation errors more obvious ([MODULES-5092](https://tickets.puppet.com/browse/MODULES-5092))
- Removed service_ensure parameter as it had no use ([MODULES-5030](https://tickets.puppet.com/browse/MODULES-5030))
- Using as_sysadmin_accounts without AS feature will error ([MODULES-2386](https://tickets.puppet.com/browse/MODULES-2386))
- SNAC_SDK shared feature can not be managed by the module ([FM-5389](https://tickets.puppet.com/browse/FM-5389))
- Purge members from SQL Server Role should actually purge ([MODULES-2543](https://tickets.puppet.com/browse/MODULES-2543))
- Identifiers are properly escaped during database creation ([FM-5021](https://tickets.puppet.com/browse/FM-5021))
- Removed forced TCP connection for SQL management ([MODULES-4915](https://tickets.puppet.com/browse/MODULES-4915))

## 2017-05-08 - Supported Release 1.2.0

### Summary

This release adds support for internationalization of the module. It also contains Japanese translations for the README, summary and description of the metadata.json and major cleanups in the README. Additional folders have been introduced called locales and readmes where translation files can be found. A number of features and bug fixes are also included in this release.

#### Features

- (MODULES-4334) - Adding locales directory, config.yaml and POT file for i18n.
- Puppet-module-gems now implemented

#### Bug Fixes

- (MODULES-4528) Replace Puppet.version comparison with Puppet::Util::Package.versioncmp
- (MODULES-4667) Update beaker tests for Jenkins CI


## 2017-03-07 - Supported Release 1.1.6

### Summary

- Minor release with a small bug fix.

#### Bug Fixes

- Fix issue where error was raised when adding or removing features if setup.exe returned 1641 (Reboot initiated) or 3010 (Reboot required) exit codes, only a warning is raised now ([MODULES-4468](https://tickets.puppetlabs.com/browse/MODULES-4468)).

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
