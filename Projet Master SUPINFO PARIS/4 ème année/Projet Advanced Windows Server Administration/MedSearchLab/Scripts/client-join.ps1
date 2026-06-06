Set-DnsClientServerAddress "-InterfaceAlias "Ethernet""
-ServerAddresses 10.10.10.10

Add-Computer "-DomainName "medsearch.local""
-Credential medsearch\Administrator `
-Restart