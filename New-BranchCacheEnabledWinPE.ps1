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
    1.0.0.3 : 05/31/2023  : Version check fix

   .LINK
    https://2pintsoftware.com
#>
# Requires the script to be run under an administrative account context.
#Requires -RunAsAdministrator

#region --------------------------------------------------[Script Parameters]------------------------------------------------------

# Set OS Image to get BranchCache binaries from. The OS version (build number, e.g. patch-level) must match boot image version.
# If using a newer Windows 11 image, patch the boot media to same level
$Windows11Media = "E:\Sources\OSD\OS\Windows 11 Enterprise x64 v21H2\sources\install.wim"

# Get the StifleR Client files from a full Windows StifleR client install (copy entire folder)
$StifleRSource = "E:\Source\OSD\2Pint\Stifler Client"

# Get the StifleR Client config file from a full Windows client 
$StifleRClientRules = "$StifleRSource\StifleR.ClientApp.exe.Config"

# Path to WinPEGen.exe
$OSDToolkitPath = "E:\Source\OSD\2Pint\OSD Toolkit 3.0.9.2 - Full\x64"

# List indexes in WIM Image
# Get-WindowsImage -ImagePath $Windows11Media

# Set other parameters
$BackupBootMedia = "E:\Source\OSD\Boot\2Pint_Win11_21H2\Backup\winpe.wim" # Optional, only needed when running the script multiple times
$BootMedia = "E:\Source\OSD\Boot\2Pint_Win11_21H2\winpe.wim"
$BootIndex = "1"

$Windows11Index = "3" #  Index 3 is Enterprise if using the WIM from a Microsoft ISO

# Optional Parameters
# Add the Root CA if using internal PKI for StifleR (certutil -ca.cert C:\Setup\Cert\CustomerRootCA.cer)
# Comment below if not used (add # infront)
$Cert = "E:\Setup\Cert\CustomerRootCA.cer"
$MountPath = "E:\Mount" # Used to mount bootimage before injecting certificat, required if $Cert is used.

#endregion -----------------------------------------------[Script Parameters]------------------------------------------------------

# Validation
$WinPEGenVersion=[version](Get-ItemProperty "$OSDToolkitPath\WinPEGen.exe").VersionInfo.FileVersion
$StifleRClientVersion=[version](Get-ItemProperty "$StifleRSource\StifleR.ClientApp.exe").VersionInfo.FileVersion
If ($WinPEGenVersion -lt [version]"3.0.2.0"){Write-Warning "WinPEGen version too old. Aborting script...";Break}
If ($StifleRClientVersion -lt [version]"2.6.9.0"){Write-Warning "StifleR Client version too old. Aborting script...";Break}

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

if($Cert) {
    Mount-WindowsImage -ImagePath $BootMedia -Index 1 -Path $MountPath
    Copy-Item -Path $Cert -Destination "$MountPath\Windows\System32" -Force 
    Dismount-WindowsImage -Path $MountPath -Save
}

# Friendly reminder
Write-Host ""
Write-Host "All done, but do NOT forget to add .NET Framework to the boot image"

