# requires puppetlabs/powershell

exec { 'samba_share':
  command => 'Mount-DiskImage \\int-resources.ops.puppetlabs.net\Resources\microsoft_sql\iso\SQLServer2014-x64-ENU.iso',
  provider => powershell,
}
