# 
# Author: Rene Weber, FAST LTA GmbH, 2020
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
    [string]$Serial,
    [string]$Description,
    [int]$Displaymode,
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



if ( !$Displaymode ){
    $Displaymode = 0
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
    Write-Host "  -Serial <Brick Serial>"
    Write-Host "  -Description <Text>"
    Write-Host "  -Displaymode <0-5>"
    Write-Host "        0 = QR - Description + ContainerID"
    Write-Host "        1 = QR - Description only"
    Write-Host "        2 = Text Display - Top & Left Aligned"
    Write-Host "        3 = Text Display - Top & Center"
    Write-Host "        4 = Text Display - Top & Right Aligned"
    Write-Host "        5 = Text Display - Middle & Center"
    exit 
}


if ( [string]::IsNullOrEmpty( $Serial ) -Or [string]::IsNullOrEmpty( $Description ) ){

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

# Reading Brick ID
if( ! ( $brickID = $mycontroller.getBrickIDBySerial( $Serial ) ) ){
    Write-Error "Brick $Serial not found"
    exit
}


### Updating a Brick Display
$ret = $mycontroller.updateBrickDescription( $Serial, $Description, $Displaymode )

if ( $ret ){
    Write-Host "Successfully updated Display."
}
else{
    Write-Error "Display update failed."
}




