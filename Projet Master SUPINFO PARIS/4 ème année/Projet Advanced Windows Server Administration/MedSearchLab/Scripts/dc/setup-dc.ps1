Write-Host "CONFIGURATION DOMAIN CONTROLLER"

Rename-Computer -NewName "DC1" -Force

New-NetIPAddress 
  -InterfaceAlias "Ethernet" 
  -IPAddress 192.168.56.10 
  -PrefixLength 24

Set-DnsClientServerAddress 
  -InterfaceAlias "Ethernet" 
  -ServerAddresses 127.0.0.1

Install-WindowsFeature AD-Domain-Services,DNS,DHCP 
  -IncludeManagementTools

Import-Module ADDSDeployment

$Password = ConvertTo-SecureString "Supinfo2026!" -AsPlainText -Force

Install-ADDSForest 
  -DomainName "medsearchlab.local" 
  -DomainNetbiosName "MEDSEARCHLAB" 
  -SafeModeAdministratorPassword $Password 
  -InstallDNS 
  -Force 
  -NoRebootOnCompletion

Restart-Computer -Force