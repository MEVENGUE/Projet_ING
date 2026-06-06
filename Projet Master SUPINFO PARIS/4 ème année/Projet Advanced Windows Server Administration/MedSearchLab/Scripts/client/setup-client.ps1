Write-Host "CONFIGURATION WINDOWS 11 CLIENT"

Set-DnsClientServerAddress 
  -InterfaceAlias "Ethernet" 
  -ServerAddresses 192.168.56.10