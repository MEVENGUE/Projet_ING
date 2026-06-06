Write-Host "CONFIGURATION FILE SERVER"

Rename-Computer -NewName "FS1" -Force

New-NetIPAddress 
  -InterfaceAlias "Ethernet" 
  -IPAddress 192.168.56.20 
  -PrefixLength 24

Set-DnsClientServerAddress 
  -InterfaceAlias "Ethernet" 
  -ServerAddresses 192.168.56.10

Install-WindowsFeature FS-FileServer 
  -IncludeManagementTools

Restart-Computer -Force