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
    [String]$Volume
)


$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {
    . ("$ScriptDirectory\FAST.ps1")
}
catch {
    Write-Error "Error while loading supporting PowerShell Scripts" 
    exit 0
}


if ( [string]::IsNullOrEmpty( $Hostname ) -Or [string]::IsNullOrEmpty( $Username ) -Or [string]::IsNullOrEmpty( $Password )  -Or [string]::IsNullOrEmpty( $Volume )){
    Write-Host "Parameters needed:"
    Write-Host "  -Hostname <hostname or IP>"
    Write-Host "  -Username <username for login>"
    Write-Host "  -Password <password for login>"
    Write-Host "  -Volume <volume name of the replication target volume>"
    exit 
}

# Initialize Object
$mycontroller = New-Object SilentBrick
$mycontroller.IP = $Hostname
$mycontroller.User = $Username
$mycontroller.Password = $Password



if( ! ( $ReplicationState = $mycontroller.getReplicationStateByTargetVolumename($Volume)) ){
    write-error "Failed to get Replication State"
    exit
}

Write-Host "Your replication is " $ReplicationState.state " at " $ReplicationState.progress " %"




