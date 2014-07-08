Import-Module sqlps -DisableNameChecking

function Get-SqlLogin{
	param($login)
  Set-Location "SQLSERVER:\SQL\${env:COMPUTERNAME}\Default\Logins"
  gci | where {$_.Name -like "*\$login"}
}

function Get-SqlIpMask {

}

# To get the password
# (ConvertTo-SecureString "P@ssword1" -AsPlainText -Force).ToString()
function Create-SqlLogin{
  param(
    [String] $loginname,
    [String] $LoginType,
    [String] $SecurePassword
    )

    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $env:COMPUTERNAME, $loginname
    $login.LoginType = $LoginType
    $login.Create((Convertto-SecureString $SecurePassword))
}