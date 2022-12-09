<#
    .Synopsis
        Script to run the WinPEGen.exe tool, adding BranchCache and StifleR to your boot image(s)

    .REQUIREMENTS
       Must have a copy of an installed StifleR Client folder

    .USAGE
       Set the parameters to match your environment in the parameters region

   .NOTES
    AUTHOR: 2Pint Software
    EMAIL: support@2pintsoftware.com
    VERSION: 1.0.0.2
    DATE:11/26/2019 
    
    CHANGE LOG: 
    1.0.0.0 : 11/26/2019  : Initial version of script 
    1.0.0.1 : 11/26/2019  : Added version checks for WinPEGen.exe and StifleR Client
    1.0.0.2 : 10/21/2022  : Added Backup and Certificate Import

   .LINK
    https://2pintsoftware.com
#>

# Requires the script to be run under an administrative account context.
#Requires -RunAsAdministrator

#
# Parameters region BEGIN
#

# Set OS Image to get BranchCache binaries from. The OS version (build number, e.g. patch-level) must match boot image version.
# If using a newer Windows 11 image, patch the boot media to same level
$Windows11Media = "E:\Setup\Windows 11 21H2 WIM\install.wim"

# Get the StifleR Client files from a full Windows StifleR client install (copy entire folder)
$StifleRSource = "E:\Setup\StifleR Client - Installed - 2.6.9.0"

# Get the StifleR Client config file from a full Windows client 
$StifleRClientRules = "$StifleRSource\StifleR.ClientApp.exe.Config"

# List indexes in WIM Image
# Get-WindowsImage -ImagePath $Windows11Media

# Set other parameters
$BackupBootMedia = "E:\Sources\OSD\Boot\Zero Touch WinPE 10 x64 - OSD Toolkit and WiFi\Backup\winpe.wim" # Optional, only needed when running the script multiple times
$BootMedia = "E:\Sources\OSD\Boot\Zero Touch WinPE 10 x64 - OSD Toolkit and WiFi\WinPE.wim"
$BootIndex = "1"
$Windows11Index = "3" #  Index 3 is Enterprise if using the WIM from a Microsoft ISO
$OSDToolkitPath = "E:\Setup\2Pint Software OSD Toolkit 3.0.2.0\x64"

#
# Parameters region END
#

# Validation
$WinPEGenVersion=(Get-ItemProperty "$OSDToolkitPath\WinPEGen.exe").VersionInfo.FileVersion
$StifleRClientVersion=(Get-ItemProperty "$StifleRSource\StifleR.ClientApp.exe").VersionInfo.FileVersion
If ($WinPEGenVersion -lt "3.0.2.0"){Write-Warning "WinPEGen version too old. Aborting script...";Break}
If ($StifleRClientVersion -lt "2.6.9.0"){Write-Warning "StifleR Client version too old. Aborting script...";Break}

If (!(Test-Path $Windows11Media)){Write-Warning "$Windows11Media missing, aborting script...";Break}
If (!(Test-Path $StifleRSource)){Write-Warning "$StifleRSource missing, aborting script...";Break}
If (!(Test-Path $StifleRClientRules)){Write-Warning "$StifleRClientRules missing, aborting script...";Break}
If (!(Test-Path $OSDToolkitPath)){Write-Warning "$OSDToolkitPath missing, aborting script...";Break}
If (!(Test-Path $BackupBootMedia)){Write-Warning "$BackupBootMedia missing, aborting script...";Break}

# Restore boot image from backup copy
If (Test-Path $BackupBootMedia){
    If (Test-Path $BootMedia) {Remove-Item $BootMedia -Force}
    Copy-item $BackupBootMedia $BootMedia
}

# Set working directory to OSDToolkitPath, and start Running WinPEGen.exe
Set-Location $OSDToolkitPath
.\WinPEGen.exe $Windows11Media $Windows11Index $Bootmedia $BootIndex /Add-StifleR /StifleRConfig:$StifleRClientRules /StifleRSource:$StifleRSource

# Delete the WinPEGen Backup
Remove-Item -Path "$($BootMedia)_original_backup" -Force

# Add the Root CA if using internal PKI for StifleR (certutil -ca.cert C:\Setup\Cert\ViaMonstraRootCA.cer)
$Cert = "E:\Setup\Cert\ViaMonstraRootCA.cer"
$MountPath = "E:\Mount"
Mount-WindowsImage -ImagePath $BootMedia -Index 1 -Path $MountPath
Copy-Item -Path $Cert -Destination "$MountPath\Windows\System32" -Force 
Dismount-WindowsImage -Path $MountPath -Save

# Friendly reminder
Write-Host ""
Write-Host "All done, but do NOT forget to add .NET Framework to the boot image"

