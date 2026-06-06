param(
    [string]$VMName,
    [string]$ISOPath
)

$VMRoot = "C:\MedSearchLab\VMs"
$VMPath = "$VMRoot\$VMName"

Write-Host "Creating VM: $VMName"

# Create VM directory
New-Item -ItemType Directory -Path $VMPath -Force

# Create virtual disk
& "C:\Program Files (x86)\VMware\VMware Workstation\vmware-vdiskmanager.exe" `
-c `
-s 25GB `
-a lsilogic `
-t 1 `
"$VMPath\$VMName.vmdk"

# Generate VMX
$VMX = @"
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "21"

displayName = "$VMName"
guestOS = "windows2022srv-64"

memsize = "4096"
numvcpus = "2"

firmware = "efi"

ethernet0.present = "TRUE"
ethernet0.connectionType = "custom"
ethernet0.vnet = "VMnet3"

ethernet1.present = "TRUE"
ethernet1.connectionType = "nat"

scsi0.present = "TRUE"
scsi0.virtualDev = "lsisas1068"

scsi0:0.present = "TRUE"
scsi0:0.fileName = "$VMName.vmdk"

sata0.present = "TRUE"

sata0:0.present = "TRUE"
sata0:0.deviceType = "cdrom-image"
sata0:0.fileName = "$ISOPath"
sata0:0.startConnected = "TRUE"

usb.present = "TRUE"

sound.present = "FALSE"

tools.syncTime = "TRUE"
"@

$VMX | Out-File "$VMPath\$VMName.vmx" -Encoding ASCII

Write-Host "VM Created Successfully."