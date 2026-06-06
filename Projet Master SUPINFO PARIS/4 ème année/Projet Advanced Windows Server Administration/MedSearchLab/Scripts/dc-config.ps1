Rename-Computer -NewName "DC-INFRA" -Force

Set-NetIPAddress "-InterfaceAlias "Ethernet""
-IPAddress 10.10.10.10 
-PrefixLength 24

Set-DnsClientServerAddress "-InterfaceAlias "Ethernet""
-ServerAddresses 127.0.0.1

Install-WindowsFeature AD-Domain-Services,DNS,DHCP -IncludeManagementTools

Import-Module ADDSDeployment

Install-ADDSForest "-DomainName "medsearch.local""
-DomainNetbiosName "MEDSEARCH" "-SafeModeAdministratorPassword"
(ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) 
-Force

Restart-Computer -Force