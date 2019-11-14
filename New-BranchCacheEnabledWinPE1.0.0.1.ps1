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
    VERSION: 1.0.0.1
    DATE:11/26/2019 
    
    CHANGE LOG: 
    1.0.0.0 : 11/26/2019  : Initial version of script 
    1.0.0.1 : 11/26/2019  : Added version checks for WinPEGen.exe and StifleR Client

   .LINK
    https://2pintsoftware.com
#>
# Check for elevation (admin rights)
if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # All OK, script is running with admin rights
}
else
{
  Write-Warning "This script needs to be run with admin rights..."
  Exit 1
}

#
# Parameters region BEGIN
#

# Set OS Image to get BranchCache binaries from. The OS version (build number, e.g. patch-level) must match boot image version.
# If using a newer Windows 10 image, patch the boot media to same level
$Windows10Media = "E:\Setup\OS Image used for OSD Toolkit\install.wim"

# Get the StifleR Client files from a full Windows StifleR client install (copy entire folder)
$StifleRSource = "E:\Setup\Installed StifleR Client"

# Get the StifleR Client config file from a full Windows client 
$StifleRClientRules = "$StifleRSource\StifleR.ClientApp.exe.Config"

# List indexes in WIM Image
# Get-WindowsImage -ImagePath $Windows10Media

# Set other parameters
$BackupBootMedia = "E:\Sources\OSD\Boot\Zero Touch WinPE 10 x64\winpe.wim_original_backup" # Optional, only needed when running the script multiple times
$BootMedia = "E:\Sources\OSD\Boot\Zero Touch WinPE 10 x64\winpe.wim"
$BootIndex = "1"
$Windows10Index = "3" #  Index 3 is Enterprise if using the WIM from a Microsoft ISO
$OSDToolkitPath = "E:\Setup\OSD Toolkit 2.1.0.3\WinPE Generator\x64"

#
# Parameters region END
#

# Validation
$WinPEGenVersion=(Get-ItemProperty "$OSDToolkitPath\WinPEGen.exe").VersionInfo.FileVersion
$StifleRClientVersion=(Get-ItemProperty "$StifleRSource\StifleR.ClientApp.exe").VersionInfo.FileVersion
If ($WinPEGenVersion -lt "2.2.1."){Write-Warning "WinPEGen version too old. Aborting script...";Break}
If ($StifleRClientVersion -lt "2.2.4.1"){Write-Warning "StifleR Client version too old. Aborting script...";Break}

If (!(Test-Path $Windows10Media)){Write-Warning "$Windows10Media missing, aborting script...";Break}
If (!(Test-Path $StifleRSource)){Write-Warning "$StifleRSource missing, aborting script...";Break}
If (!(Test-Path $StifleRClientRules)){Write-Warning "$StifleRClientRules missing, aborting script...";Break}
# If (!(Test-Path $BackupBootMedia)){Write-Warning "$BackupBootMedia missing, aborting script...";Break}
If (!(Test-Path $BootMedia)){Write-Warning "$BootMedia missing, aborting script...";Break}
If (!(Test-Path $OSDToolkitPath)){Write-Warning "$OSDToolkitPath missing, aborting script...";Break}


# Restore boot image from backup copy
If (Test-Path $BackupBootMedia){
    Remove-Item $BootMedia -Force
    Copy-item $BackupBootMedia $BootMedia
}


# Set working directory to OSDToolkitPath, and start Running WinPEGen.exe
Set-Location $OSDToolkitPath
.\WinPEGen.exe $Windows10Media $Windows10Index $Bootmedia $BootIndex /Add-StifleR /StifleRConfig:$StifleRClientRules /StifleRSource:$StifleRSource

# Friendly reminder
# Write-Host ""
# Write-Host "All done, but do NOT forget to add .NET Framework to the boot image"
