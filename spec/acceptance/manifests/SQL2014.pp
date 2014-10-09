# requires puppetlabs/powershell

exec { 'samba_share':
  command => 'Mount-DiskImage \\int-resources.ops.puppetlabs.net\Resources\ISO\Windows\SQL_Server\SQLServer2014-x64-ENU.iso',
  provider => powershell,
}
