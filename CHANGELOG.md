# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v3.0.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v3.0.0) (2021-02-27)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v2.6.2...v3.0.0)

### Changed

- pdksync - Remove Puppet 5 from testing and bump minimal version to 6.0.0 [\#369](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/369) ([carabasdaniel](https://github.com/carabasdaniel))

### Added

- pdksync - \(feat\) - Add support for Puppet 7 [\#363](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/363) ([daianamezdrea](https://github.com/daianamezdrea))

### Fixed

- \(FM-8879\) Handle T-SQL Errors Properly [\#349](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/349) ([RandomNoun7](https://github.com/RandomNoun7))

## [v2.6.2](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v2.6.2) (2020-01-21)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v2.6.1...v2.6.2)

### Fixed

- \(MODULES-10384\) - Registry value check tightened [\#343](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/343) ([david22swan](https://github.com/david22swan))
- \(MODULES-10335\) - Update exec's title to be unique [\#341](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/341) ([david22swan](https://github.com/david22swan))

## [v2.6.1](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v2.6.1) (2020-01-16)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v2.6.0...v2.6.1)

### Fixed

- \(MODULES-10388\) fix missing gem [\#339](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/339) ([sheenaajay](https://github.com/sheenaajay))

## [v2.6.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v2.6.0) (2019-10-21)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v2.5.1...v2.6.0)

### Added

- Add support for Server 2019 [\#327](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/327) ([sanfrancrisko](https://github.com/sanfrancrisko))

## v2.5.1

### Fixed

- Add DQC to sqlserver_features feature attribute ([MODULES-8600](https://tickets.puppetlabs.com/browse/MODULES-8600))
- Fix sqlserver_instances fact fails when registry contains uninstalled instances ([MODULES-8439](https://tickets.puppetlabs.com/browse/MODULES-8439))
- Switch to using PowerShell `Restart-Service .. -Force` to restart the SQLServer service in `sqlserver::sp_configure` ([MODULES-6904](https://tickets.puppetlabs.com/browse/MODULES-6904))
- Fix ERB Template Errors ([MODULES-9912](https://tickets.puppetlabs.com/browse/MODULES-9912))

## [2.5.0] - 2019-03-26

## Added

- Bolt task to start SQL agent jobs ([MODULES-8610](https://tickets.puppetlabs.com/browse/MODULES-8610)).

## Fixed

- Missing type declaration for the get_sqlagent_job.json
- Make job_name param required for the start_sql_agent_job task ([MODULES-8749](https://tickets.puppetlabs.com/browse/MODULES-8749))

## [2.4.0] - 2019-03-12

### Added

- Get agent jobs Bolt task ([MODULES-8692](https://tickets.puppetlabs.com/browse/MODULES-8692))
- Get sql logins Bolt task ([MODULES-8606](https://tickets.puppetlabs.com/browse/MODULES-8606))
- Set sql logins Bolt task ([MODULES-8606](https://tickets.puppetlabs.com/browse/MODULES-8606))

### Fixed

- Cannot manage a role with the same name on two instances or two databases ([MODULES-8677](https://tickets.puppetlabs.com/browse/MODULES-8677)) (Thanks [Dylan Ratcliffe](https://github.com/dylanratcliffe))
- Removing a SQL Login via `ensure => absent` in a sqlserver::login resource is not idempotent. ([MODULES-8685](https://tickets.puppetlabs.com/browse/MODULES-8685)) (Thanks [Dylan Ratcliffe](https://github.com/dylanratcliffe))

## [2.3.0] - 2019-01-22

### Added

- Add support for installing and managing SQL 2019 instances ([MODULES-8438](https://tickets.puppetlabs.com/browse/MODULES-8438))

### Changed

- License terms updated to allow a Bolt trial period ([License](https://github.com/puppetlabs/puppetlabs-sqlserver/blob/main/LICENSE))

### Fixed

- .NET 3.5 could be installed in cases where it was not necessary. ([MODULES-8438](https://tickets.puppetlabs.com/browse/MODULES-8438))
- Features were not detected correctly if the registry keys were stored with a value other than 1. (Thanks [GrammatonKlaric](https://github.com/GrammatonKlaric)) ([MODULES-7734](https://tickets.puppetlabs.com/browse/MODULES-7734))

## [2.2.0] - 2018-12-3

### Added
- Convert module for PDK ([MODULES-7406](https://tickets.puppetlabs.com/browse/MODULES-7406))

### Changed
- Update support for Puppet version 6. ([MODULES-7833](https://tickets.puppetlabs.com/browse/MODULES-7833))
- Update README_ja_JP.md
- Update stdlib version to 6. ([MODULES-7705](https://tickets.puppetlabs.com/browse/MODULES-7705))


## [2.1.1] - 2018-03-14

### Added
- Add CONTRIBUTING.md ([FM-6605](https://tickets.puppetlabs.com/browse/FM-6605))

### Fixed

- Fix problem installing sql instance when an array of SQL Admins are specified. ([MODULES-6356](https://tickets.puppetlabs.com/browse/MODULES-6356))
- Fix AppVeyor OpenSSL bug.([Modsync commit with discussion](https://github.com/puppetlabs/modulesync_configs/commit/f04d0d1119cb5cbd4c3aac76047c4c766ae1fcb2))
- During acceptance testing, only execute server provisioning steps if there is
  a server in the hosts array.
- Stop running `gem update bundler` during Travis runs. ([MODULES-6339](https://tickets.puppetlabs.com/browse/MODULES-6339))
- The `sqlserver_tsql` resource now returns errors from sql queries properly. ([MODULES-6281](https://tickets.puppetlabs.com/browse/MODULES-6281))

## [2.1.0] - 2017-12-8

### Added

- Add support for installing and managing SQL 2017 instances. ([MODULES-6168](https://tickets.puppetlabs.com/browse/MODULES-6168))

### Changed

- Update documentation to reflect change that adds 2017 support. ([MODULES-6244](https://tickets.puppetlabs.com/browse/MODULES-6244))

## [2.0.2]  - 2017-12-5

### Fixed

- Fix bug where Puppet will not detect existing sql instances properly and
attempts to reinstall an instance that already exists ([MODULES-6022](https://tickets.puppetlabs.com/browse/MODULES-6022))

## [2.0.1] - 2017-11-15

### Changed

- Allow connections over TLS 1.1+ by replacing OLEDB driver with SQL Native Client ([MODULES-5693](https://tickets.puppetlabs.com/browse/MODULES-5693))
- Updated documentation to include 2016 as a supported version of SQL Server

### Fixed

- Ensure instances without SQL Engine are discoverable ([MODULES-5566](https://tickets.puppetlabs.com/browse/MODULES-5566))

## [2.0.0] - 2017-08-10

### Added

- Added more detailed examples to the README
- Updated with Puppet 4 data types ([MODULES-5126](https://tickets.puppet.com/browse/MODULES-5126))
- Added parameters to manage PolyBase ([MODULES-5070](https://tickets.puppet.com/browse/MODULES-5070))
- Added support for Windows Server 2016
- Added test tiering and test mode switcher ([FM-5062](https://tickets.puppet.com/browse/FM-5062), [FM-6141](https://tickets.puppet.com/browse/FM-6141))
- Make .Net installation errors more obvious ([MODULES-5092](https://tickets.puppet.com/browse/MODULES-5092))

### Changed

- Updated metadata for Puppet 5 ([MODULES-5144](https://tickets.puppet.com/browse/MODULES-5144))

### Deprecated

- Deprecated the use of `Tools` and `SQL` as installation features ([MODULES-4257](https://tickets.puppet.com/browse/MODULES-4257))

### Removed

- Removed unsupported Puppet versions from metadata ([MODULES-4842](https://tickets.puppet.com/browse/MODULES-4842))
- Removed support for Stdlib on unsupported Puppet versions, (Stdlib versions less than 4.13.0)
- Removed service_ensure parameter as it had no use ([MODULES-5030](https://tickets.puppet.com/browse/MODULES-5030))

### Fixed

- Using as_sysadmin_accounts without AS feature will error ([MODULES-2386](https://tickets.puppet.com/browse/MODULES-2386))
- SNAC_SDK shared feature can not be managed by the module ([FM-5389](https://tickets.puppet.com/browse/FM-5389))
- Purge members from SQL Server Role should actually purge ([MODULES-2543](https://tickets.puppet.com/browse/MODULES-2543))
- Identifiers are properly escaped during database creation ([FM-5021](https://tickets.puppet.com/browse/FM-5021))
- Removed forced TCP connection for SQL management ([MODULES-4915](https://tickets.puppet.com/browse/MODULES-4915))

## [1.2.0] - 2017-05-08

### Added

- Added locales directory, config.yaml and POT file for i18n. ([MODULES-4334](https://tickets.puppet.com/browse/MODULES-4334))
- Puppet-module-gems now implemented

### Fixed

- Replace Puppet.version comparison with Puppet::Util::Package.versioncmp ([MODULES-4528](https://tickets.puppetlabs.com/browse/MODULES-4528))
- Update beaker tests for Jenkins CI ([MODULES-4667](https://tickets.puppet.com/browse/MODULES-4667))


## [1.16] - 2017-03-07

### Fixed

- Fix issue where error was raised when adding or removing features if setup.exe returned 1641 (Reboot initiated) or 3010 (Reboot required) exit codes, only a warning is raised now ([MODULES-4468](https://tickets.puppetlabs.com/browse/MODULES-4468)).

## [1.1.5] - 2017-02-15

### Added

- Obfuscate passwords in logs if sqlserver_instance raises an error ([MODULES-4255](https://tickets.puppet.com/browse/MODULES-4255)).

### Fixed

- Fix issues with installing .Net 3.5 in acceptance tests
- Fix various issues with test environment in AppVeyor, Travis CI and Jenkins
- Fix documentation for localizationb

## [1.1.4] - 2016-08-31

### Added

- Add `windows_feature_source` parameter to the `sqlserver_instance` and `sqlserver_features` resources. This specifies the location of the Windows Feature source files, which might be needed to install the .NET Framework. See https://support.microsoft.com/en-us/kb/2734782 for more information ([MODULES-3202](https://tickets.puppet.com/browse/MODULES-3202)).

### Fixed

- Fix issues when adding multiple SYSADMIN role accounts on instance creation ([MODULES-3427](https://tickets.puppet.com/browse/MODULES-3427)).
- Fix issues when creating and deleting Windows base logins ([MODULES-3256](https://tickets.puppet.com/browse/MODULES-3256)).
- Fix errors when deleting MS SQL Server logins ([MODULES-2323](https://tickets.puppet.com/browse/MODULES-2323)) and databases ([MODULES-2554](https://tickets.puppet.com/browse/MODULES-2554)).
- Refactor acceptance tests for `sqlserver::login` resource ([MODULES-3256](https://tickets.puppet.com/browse/MODULES-3256)).
- Fix issues when modifying server roles for an existing login ([MODULES-3083](https://tickets.puppet.com/browse/MODULES-3083)).
- Fix issues when modifying an existing Windows user login ([MODULES-3752](https://tickets.puppet.com/browse/MODULES-3752)).

## [1.1.3] - 2016-07-12

### Added

- Update documentation with a more advanced SQL example.
- Add Windows Based Authentication for `sqlserver::config`. Modifies the `sqlserver::config` class with an additional property called `login_type` which can be either `SQL_LOGIN` or `WINDOWS_LOGIN`, with a default of `SQL_LOGIN`.

### Changed
- Minor refactoring of code which is not used or makes code path more obvious.

### Fixed

- Fix Role Name Collisions. This fix introduces the database name into the title created for the `sqlserver_tsql` statements so that it is unique.
- Fix TSQL error propagation. Introduce a minor refactor so that the `returns` property captures errors properly from TSQL executions.
- Emit debug output on failed `onlyif` TSQL. Previously, there was no way of getting the log output from SQL Server when executing TSQL during an `onlyif`.

## [1.1.2] - 2016-04-11

### Changed

- Update supported Puppet version ranges.

## [1.1.1] - 2015-12-08

### Changed

- Support newer PE versions.

## [1.1.0] - 2015-09-08

### Added

- `sqlserver_instance` and `sqlserver_features` have new parameter `install_switches`, which takes a hash of install switches and writes them to a temporary configuration file for the install process. ([FM-2303](https://tickets.puppetlabs.com/browse/FM-2303))
- Add define for permissions for Users, Roles, and Logins.
- New `sqlserver_tsql` provider available to execute custom scripts.

### Changed

- Remove dependency on 'sqlcmd.exe'. ([FM-2577](https://tickets.puppetlabs.com/browse/FM2577))
- `sqlserver::config` no longer writes a file to the sytem.
- Performance discovery improvements.

### Removed

- Remove dependency for ACL modules.

### Fixed

- Munge values for instance names to always be uppercase when comparing.
- Change the way we look up logins to use sys.server_principals instead of a function that might not report correctly.
- Fix issue with `collation_name` and databases where the variable was not named properly, causing it to never be set.

## [1.0.0] - 2014-12-08

Initial release.

[Unreleased]: https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v2.5.1..main
[2.5.1]: https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.5.0..v2.5.1
[2.5.0]: https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.4.0..2.5.0
[2.4.0]: https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.3.0..2.4.0
[2.3.0]: https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.2.0..2.3.0
[2.2.0]: https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.1.1..2.2.0


\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
