##2015-01-xx - 1.1.0

###Summary
Add sqlserver_tsql provider that to enable users to run sql against a given instance

###Features
* sqlserver_tsql added
* Better logging for ::login ::database and ::sp_configure
* `sqlserver_instance` and `sqlserver_features` have new parameter `install_switches` which takes a hash of install switches and writes them to a temp configuration file for the the install process

##2014-12-08 - 1.0.0
Initial release
