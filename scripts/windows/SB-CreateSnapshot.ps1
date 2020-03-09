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
    [string]$Name,
    [string]$Prefix,
    [String]$Desc,
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




if ( [string]::IsNullOrEmpty( $Name ) ){
    $Name = [DateTimeOffset]::Now.ToUnixTimeSeconds()
}

if ( [string]::IsNullOrEmpty( $Prefix ) ){
    $Prefix = "API-Call"
}

$Name = "$Prefix-$Name"

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
    Write-Host "  -Name <snapshotname>  | Optional. Default: Current Timestamp"
    Write-Host "  -Prefix <name prefix> | Optional. Default: 'API-Call'"
    Write-Host "  -Desc <description>   | Optional"
    exit 
}


if ( [string]::IsNullOrEmpty( $Volume ) ){
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


### Creating Snapshots 
$ret = $mycontroller.createSnapshot( $mycontroller.getVolumeIDByName( $Volume ), $Name, $Desc )

if ( $ret ){
    Write-Host "Created successfully"
}
else{
    Write-Error "Creation failed."
}


