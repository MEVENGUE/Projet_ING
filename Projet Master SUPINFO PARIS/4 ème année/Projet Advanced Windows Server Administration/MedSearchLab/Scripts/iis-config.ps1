Install-WindowsFeature Web-Server ",Web-Mgmt-Tools",RSAT 
-IncludeManagementTools

New-Item -ItemType Directory -Path C:\Sites\ResearchPortal -Force

Set-Content "-Path C:\Sites\ResearchPortal\index.html"
-Value "<h1>MedSearch Research Portal</h1>"

Import-Module WebAdministration

New-Website "-Name "ResearchPortal""
-Port 80 
-PhysicalPath "C:\Sites\ResearchPortal"

Enable-PSRemoting -Force

New-NetFirewallRule "-DisplayName "WinRM""
-Direction Inbound "-Protocol TCP"
-LocalPort 5985 `
-Action Allow