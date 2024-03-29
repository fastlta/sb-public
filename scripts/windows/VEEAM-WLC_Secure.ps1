# 
# Author: Rene Weber, FAST LTA GmbH, 2020
#
# Script: Veeam Write Lock Cleanup
#
# Purpose: 
# Script to be added to Veeam in order to be executed directly after the backup.
# It will 
# - Create a new Snapshot ( with an optional prefix )
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
    [String]$Prefix,
    [int]$Minutes,
    [string]$Configfile
)


$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {
    . ("$ScriptDirectory\FAST.ps1")
}
catch {
    Write-Error "Error while loading supporting PowerShell Scripts" 
    exit 1
}

function help 
{
    Write-Host "Parameters needed:"
    Write-Host "Commandline Authentication:"
    Write-Host "  -Hostname <hostname or IP>"
    Write-Host "  -Username <username for login>"
    Write-Host "  -Password <password for login>"
    Write-Host " "
    Write-Host "Configfile Authentication:"
    Write-Host "  -Configfile <filename>"
    Write-Host " "
    Write-Host "  -Volume <volume name>"
    Write-Host "  -Minutes <Age in minutes, all older snapshots will be deleted exluding the currently created one>"
    Write-Host "  -Prefix <prefix> | Optional, only delete snapshots matching prefix"
    exit 1
}

if ( [string]::IsNullOrEmpty( $Volume ) -Or !$Minutes){
    help
}



$mycontroller = New-Object SilentBrick


if( -Not [string]::IsNullOrEmpty( $Configfile ) ){
    $mycontroller.StartXMLConfig( $Configfile )

}elseif( -Not ( [string]::IsNullOrEmpty( $Username ) -Or [string]::IsNullOrEmpty( $Password ) ) ){
    $mycontroller.IP = $Hostname
    $mycontroller.User = $Username
    $mycontroller.Password = $Password
}else{
    help
}









$Name   = [DateTimeOffset]::Now.ToUnixTimeSeconds()

if( [string]::IsNullOrEmpty( $Prefix ) ){
    $Prefix = "VEEAM-Backup"
}

$NewSnapshotName = "$Prefix-$Name"


############# Get Volume ID ########################################


$uuid  = $mycontroller.getVolumeIDByName( $Volume )

if( ! $uuid ){
     write-host "Volume '$volume' not found" 
    exit 1
}


############# Create new Snapshot ########################################

$ret = $mycontroller.createSnapshot( $uuid, $NewSnapshotName, "Automatic creation by Veeam Job" )

if ( $ret ){
    Write-Host "Created snapshot $NewSnapshotName successfully"
}
else{
    Write-Error "Creation failed."
}


############# Clean Up Old Snapshots #####################################

# Read available snapshots
$objSnapshots   = $mycontroller.getSnapshotsByVolumeID( $uuid )

if( ! $objSnapshots ){
    write-host "No Snapshots found"
    exit 1
}

$intDeletedCount = 0

$objSnapshots | foreach-object {

    $uuid          = $_.uuid
    $name          = $_.name
    $label         = $_.label
 
    if ( -Not $name.StartsWith( $Prefix ) ){
        return
    }

    $creation_date = [datetime]::ParseExact($_.label, "yyyyMMdd_HHmmss", $null) 


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

exit 0







