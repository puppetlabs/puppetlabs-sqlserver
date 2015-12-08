##2015-12-08 - Supported Release 1.1.1
###Summary

Small release for support of newer PE versions.

##2015-09-08 - Supported Release 1.1.0
###Summary

User, Roles and Login as well as they permissions associated with each are now available.

####Features
- `sqlserver_instance` and `sqlserver_features` have new parameter `install_switches` which takes a hash of install switches and writes them to a temp configuration file for the the install process
- Add define for permissions for Users, Roles and Logins
- `sqlserver::config` no longer writes a file to the sytem
- New `sqlserver_tsql` provider available to execute custom scripts
- Remove dependency on 'sqlcmd.exe'
- Performance discovery improvements
- Remove dependency for ACL modules

####Bug Fixes
- Munge values for instance names to always be uppercase when comparing
- Change the way we look up logins to use sys.server_principals instead of function that might not report correctly
- Fix issue with collation_name and databases where the variable was not named properly causing it to never be set

##2014-12-08 - 1.0.0
Initial release
