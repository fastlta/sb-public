# 
# Author: Rene Weber, FAST LTA AG, 2018
#
# Script: Continous Snapshot
#
# Purpose: 
# Script to be triggered by task planner in recurring time frames depending on the change rate
# It will 
# - Create a new Snapshot ( with continous snapshot prefix )
# - Delete old Snapshots ( matching the prefix and the age in Minutes )
# 
# Compatibility: Powershell Version >= 5
#
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)

param(
    [string]$Hostname,
    [string]$Username,
    [string]$Password,
    [string]$Volume,
    [int]$Minutes
)


$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {
    . ("$ScriptDirectory\FAST.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
    exit 0
}


if ( [string]::IsNullOrEmpty( $Hostname ) -Or [string]::IsNullOrEmpty( $Username ) -Or [string]::IsNullOrEmpty( $Password ) -Or [string]::IsNullOrEmpty( $Volume ) -Or !$Minutes){
    Write-Host "Parameters needed:"
    Write-Host "  -Hostname <hostname or IP>"
    Write-Host "  -Username <username for login>"
    Write-Host "  -Password <password for login>"
    Write-Host "  -Volume <volume name>"
    Write-Host "  -Minutes <Age in minutes, all older snapshots will be deleted exluding the currently created one>"
    exit 
}

write-debug "Hostname is $Hostname, User is $Username, Pass is $Password"



############# Connect to your System #####################################

$mycontroller = New-Object SilentBrick

$mycontroller.IP = $Hostname
$mycontroller.User = $Username
$mycontroller.Password = $Password


############# get current snapshots from the volume  #####################################

$uuid           = $mycontroller.getVolumeIDByName( $Volume )
$objSnapshots   = $mycontroller.getSnapshotsByVolumeID( $uuid )


############# Check for maximum snapshot count of 200
$countSnapshots = $objSnapshots | measure

if( $countSnapshots.Count -gt 198 ) {
    Write-Error("Maximum Number of Snapshots reached! Please delete Snapshots before adding new Snapshots")
    exit
}
Write-Host "Found " $countSnapshots.Count " Snapshots"



############# Check for volume fill state
$objVolume     = $mycontroller.GetVolumeByName( $Volume )

$usedPercentage = ( $objVolume.used / $objVolume.size ) * 100

if( $usedPercentage -gt 95 ){
     Write-Error("Fill state is higher than 95%! Please delete Snapshots, Data or extend your Volume before adding new Snapshots")
     exit 
}
        


############# Create new Snapshot ########################################

$Name   = [DateTimeOffset]::Now.ToUnixTimeSeconds()

$Prefix = "ContinousSnapshot"


$NewSnapshotName = "$Prefix-$Name"


$ret = $mycontroller.createSnapshot( $mycontroller.getVolumeIDByName( $Volume ), $NewSnapshotName, "Automatic creation by the continous snapshot tool" )

if ( $ret ){
    Write-Host "Created snapshot $NewSnapshotName successfully"
}
else{
    Write-Error "Creation failed."
}


############# Clean Up Old Snapshots #####################################



if( ! $objSnapshots ){
    write-debug "No Snapshots found"
    exit
}

$intDeletedCount = 0

$objSnapshots | foreach-object {
    $creation_date = [datetime]::ParseExact($_.label, "yyyyMMdd_HHmmss", $null)
    $uuid          = $_.uuid
    $name          = $_.name
    $label         = $_.label

    $deletion_offset = (Get-Date).AddMinutes(-$Minutes)

    if ( $creation_date -lt $deletion_offset -And ! $name.StartsWith( $NewSnapshotName )  )
    {
        Write-Host "Found Snapshot $name with $creation_date beeing older than $Minutes minutes ( $deletion_offset )"

        if ( $name.StartsWith( $Prefix )  )
        {
            Write-debug "Snapshot matches Prefix. Deleting."
            if( $mycontroller.deleteSnapshotByID( $uuid ) ){
                $intDeletedCount++
                write-debug "Snapshot deleted: $uuid, $name, $label"
             }
             
        }
    }

}

write-debug "Deleted $intDeletedCount Snapshots"









