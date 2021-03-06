# 
# Author: Rene Weber, FAST LTA GmbH, 2020
#
# Script: DeleteSnapshotsByAge
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
    [int]$Days,
    [String]$Prefix,
    [String]$Configfile
)


$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {
    . ("$ScriptDirectory\FAST.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
    exit 0
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
    Write-Host "  -Days <number of days, all older snapshots will be deleted>"
    Write-Host "  -Prefix <prefix> | Optional, only delete snapshots matching prefix"
    exit 
}


if ( [string]::IsNullOrEmpty( $Volume ) -Or !$Days ){
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

    $deletion_offset = (Get-Date).AddDays(-$Days)

    if ( $creation_date -lt $deletion_offset )
    {
        Write-Host "Found Snapshot $name beeing older than $Days days ( $label )"

        if( [String]::IsNullOrEmpty( $Prefix ) )
        {
             Write-Host "Prefix check not enabled. Deleting."  
             if( $mycontroller.deleteSnapshotByID( $uuid ) ){
                $intDeletedCount++
                write-debug "Snapshot deleted: $uuid, $name, $label"
             }
        }
        elseif ( $name.StartsWith( $Prefix )  )
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









