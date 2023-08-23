<#
.SYNOPSIS
  Get-BitsTSInfoFromRegistry.ps1

.DESCRIPTION
  Enumerates all items under HKLM:\SOFTWARE\2Pint Software\BITST into a table for easier viewing.

.PARAMETER Path
  Path and name to where the csv will be created.

.PARAMETER GridView
  Shows the result in a PowerShell GridView

.NOTES
  Version:        1.2
  Author:         2Pint Software
  Creation Date:  10/28/2022
  Purpose/Change: Initial script development
  Updated:        08/22/2023
  Supported BitsACP Client = 3.1.3.0+

.LINK
  https://2pintsoftware.com

.EXAMPLE
  Get-BitsTSInfoFromRegistry.ps1 -path "$env:TEMP\Bitsdeployments.csv
  
  Exports the results to a csv in the specified location.

.EXAMPLE
  Get-BitsTSInfoFromRegistry.ps1 -GridView
  
  Shows the results on screen using PowerShells builtin out-gridview function.

#>
#region --------------------------------------------------[Script Parameters]------------------------------------------------------
Param (
  [parameter(Mandatory = $false)]
  [string]$path,
  [parameter(Mandatory = $false)]   
  [switch]$GridView,
  [parameter(Mandatory = $false)]   
  [switch]$UTCtoLocalTime
)
#endregion -----------------------------------------------[Script Parameters]------------------------------------------------------
#region --------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'
$2PReg = "HKLM:\SOFTWARE\2Pint Software"

#endregion -----------------------------------------------[Initialisations]--------------------------------------------------------
# -----------------------------------------------------------[Execution]------------------------------------------------------------
if (-not $path -and -not $GridView) {
  Write-Warning "Either -path or -Gridview parameter needs to be set"
  exit
}

if (-not (Test-Path $2PReg)) {

  Write-Warning "2Pint Software registry key does not exist"
  if (-not (Test-Path "$2PReg\BITSTS")) {

    Write-Warning "2Pint Software registry key does not exist"
    exit
  }
  exit
}

$ComputerName = $env:COMPUTERNAME
$ResultList = $null
$ResultList = [System.Collections.Generic.List[object]]::new()
if ($UTCtoLocalTime) {
  $UTCOffset = ([datetime]::Now - [DateTime]::UtcNow).Hours
}


Foreach ($deploymentID in (Get-ChildItem -Path "$2PReg\BITSTS").PSChildName) { 

  $deploymentList = $null
  $deploymentList = [System.Collections.Generic.List[object]]::new()

  foreach ($PackageID in (Get-childItem -Path "$2PReg\BITSTS\$($deploymentID)").PSChildName) { 

    $items = Get-Item -Path "$2PReg\BITSTS\$($deploymentID)\$PackageID" | Select-Object -ExpandProperty property

    $Properties = $null
    $Properties = [ordered]@{
      ComputerName                      = $ComputerName
      DeploymentID                      = $deploymentID
      PackageID                         = $PackageID
      Step                              = ''
      StepName                          = ''
      StartTime                         = ''
      EndTime                           = ''
      TotalDurationMin                  = ''
      TimetoNextMin                     = ''
      StatusText                        = ''                                                                           
      HttpStatus                        = ''                                                                                       
      Source                            = ''                               
      FilesTotal                        = ''                                                                                     
      FilesTransferred                  = ''                                                                                           
      SmallFilesCount                   = ''
      SmallFilesSize                    = ''
      BytesTransferredBITS              = ''                                                                                
      BytesTotal                        = ''                                                                                
      BytesFromSource                   = ''                                                                                   
      BytesFromPeers                    = ''
      BytesTotalTurbo                   = ''                                                                                 
      TurboDuration                     = ''                                                                                 
      TurboSpeed                        = ''
      'TurboFiles (bytes - returncode)' = ''                                                                                    
      SequenceBytesFromSourceBefore     = ''                                                                                      
      SequenceBytesFromPeersBefore      = ''                                                                                     
      SequenceBytesFromSource           = ''                                                                                 
      SequenceBytesFromPeers            = ''                                                                                   
      ExitCode                          = '' 
    }
    
    [array]$BTproperties = ((Get-ItemProperty -path "$2PReg\BITSTS\$($deploymentID)\$PackageID").PSObject.Properties | Where-Object { $_.Name -like "BytesTotal_*" }).Name
    [array]$Turboproperties = ((Get-ItemProperty -path "$2PReg\BITSTS\$($deploymentID)\$PackageID").PSObject.Properties | Where-Object { $_.Name -like "TurboReturnCode_*" }).Name

    Foreach ($item in $items) {
      if ($Turboproperties -notcontains $item -and $BTproperties -notcontains $item) {
        switch ($item) {
          "BytesTransferred" { $Properties."BytesTransferredBITS" = Get-ItemPropertyValue -Path "$2PReg\BITSTS\$($deploymentID)\$PackageID" -Name $item }
          Default {
            $Properties."$item" = Get-ItemPropertyValue -Path "$2PReg\BITSTS\$($deploymentID)\$PackageID" -Name $item
          }
        }
      }
    }
    
    if ($BTproperties) {
      $filenames = @()
      Foreach ($prop in $BTproperties) {
        $value = Get-ItemPropertyValue -Path "$2PReg\BITSTS\$($deploymentID)\$PackageID" -Name $prop
        $Name = ($prop -split "BytesTotal_")[1]
        try { $TurboRetCode = Get-ItemPropertyValue -Path "$2PReg\BITSTS\$($deploymentID)\$PackageID" -Name "TurboReturnCode_$Name" } catch {}
        $filenames += "$Name ($value - $TurboRetCode)"
      }
      $Properties.'TurboFiles (bytes - returncode)' = $filenames -join ","
    }
    $Properties.TotalDurationMin = [math]::Round(([DateTime]$Properties.EndTime - [DateTime]$Properties.StartTime).TotalMinutes, 2)
    if ($UTCtoLocalTime) {
      $Properties.StartTime = "{0:yyyy-MM-dd HH:mm:ss}" -f ([DateTime]$Properties.StartTime).AddHours($UTCOffset)
      $Properties.EndTime = "{0:yyyy-MM-dd HH:mm:ss}" -f ([DateTime]$Properties.EndTime).AddHours($UTCOffset)
    } 

    $deploymentList.Add((New-Object PsObject -Property $Properties))
  }

  $sortedList = $deploymentList | Sort-Object -Property EndTime
  for ($i = 0; $i -lt ($sortedList.Count - 1); $i++) {
    $j = $i + 1
    $sortedList[$i].TimetoNextMin = [math]::Round(([DateTime]$sortedList[$j].StartTime - [DateTime]$sortedList[$i].EndTime).TotalMinutes, 2)
  }

  $ResultList += $deploymentList
}

if ($path) { $ResultList | Sort-Object -Property Step | Export-csv -path $path -Force -NoClobber -NoTypeInformation -Delimiter ";" }
if ($GridView) { $ResultList | Sort-Object -Property Step | Out-GridView }