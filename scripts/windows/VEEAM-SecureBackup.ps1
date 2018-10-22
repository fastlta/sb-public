# 
# Author: Rene Weber, FAST LTA AG, 2017
#
# Script: GetSnapshots
#
# Purpose: Provide a Windows Script sample how to collect information from the public API of
#          the FAST LTA AG Silent Bricks System
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)

# inital values to adjust for the connection to the SB controllers
# Change these to adress your controller.s

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
    Write-Host "  -Prefix <prefix> | Optional, only delete snapshots matching prefix"
    exit 
}

write-debug "Hostname is $Hostname, User is $Username, Pass is $Password"



$mycontroller = New-Object SilentBrick

$mycontroller.IP = $Hostname
$mycontroller.User = $Username
$mycontroller.Password = $Password


$Name   = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$Prefix = "VEEAM-Backup"

$NewSnapshotName = "$Prefix-$Name"

############# Create new Snapshot ########################################

$ret = $mycontroller.createSnapshot( $mycontroller.getVolumeIDByName( $Volume ), $NewSnapshotName, "Automatic creation by Veeam Job" )

if ( $ret ){
    Write-Host "Created snapshot $NewSnapshotName successfully"
}
else{
    Write-Error "Creation failed."
}


############# Clean Up Old Snapshots #####################################

# Read available snapshots
$uuid           = $mycontroller.getVolumeIDByName( $Volume )
$objSnapshots   = $mycontroller.getSnapshotsByVolumeID( $uuid )

if( ! $objSnapshots ){
    write-host "No Snapshots found"
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
            Write-Host "Snapshot matches Prefix. Deleting."
            if( $mycontroller.deleteSnapshotByID( $uuid ) ){
                $intDeletedCount++
                write-debug "Snapshot deleted: $uuid, $name, $label"
             }
             
        }
    }

}

write-host "Deleted $intDeletedCount Snapshots"









