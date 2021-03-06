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




$mycontroller = New-Object SilentBrick

#$configfile = $mycontroller.CreateConfigfileInteractively()


$mycontroller.StartXMLConfig( $Configfile )




 

 



### Checking for running tasks
$ret = $mycontroller.getTasksRunning( )


if( $ret ){
    Write-Host "Communication succeeded. Target is busy."
}
else{
    Write-Host "Communication succeeded. Target waiting for tasks."
}


