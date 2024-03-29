# 
# Author: Rene Weber, FAST LTA GmbH, 2023
#
# Script: GetShareInfos
#
# Purpose: Provide a Windows Script sample how to collect information from the public API of
#          the FAST LTA AG Silent Bricks System
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)

# inital values to adjust for the connection to the SB controllers
# Change these to adress your controller

param(
    [string]$Hostname,
    [string]$Username,
    [string]$Password,
    [string]$Configfile
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
    exit 
}




$mycontroller = New-Object SilentBrick


if( -Not [string]::IsNullOrEmpty( $Configfile ) ){
    $mycontroller.StartXMLConfig( $Configfile )

}elseif( -Not ( [string]::IsNullOrEmpty( $Username ) -Or [string]::IsNullOrEmpty( $Password ) -Or [string]::IsNullOrEmpty( $Hostname )  ) ){
    $mycontroller.IP = $Hostname
    $mycontroller.User = $Username
    $mycontroller.Password = $Password
}else{
    help
}


# Share HANDLING
$objShares     = $mycontroller.getShares()

Write-Host "----- All Shares "
Write-Host ($objShares | Format-Table | Out-String )

$objShares | foreach-object { 

    $strShareID   = $_.uuid
    $strShareName = $_.name
    $strVolumeId  = $_.volume_uuid

    $objVolume    = $mycontroller.getVolumeByID($strVolumeId);
    $strVolName   = $objVolume.name;

    Write-Host  "------- Share with Name $strShareName is assigned to Volume $strVolName"
 }

