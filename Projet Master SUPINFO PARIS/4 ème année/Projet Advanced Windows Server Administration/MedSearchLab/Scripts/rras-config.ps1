Install-WindowsFeature RemoteAccess ",VPN",Routing `
-IncludeManagementTools

Install-RemoteAccess -VpnType Vpn

Restart-Service RemoteAccess