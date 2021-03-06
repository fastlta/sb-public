# 
# Author: Rene Weber, FAST LTA GmbH, 2020
#
# Script: SB System XML Creator
#
# Purpose: 
# Provides a User Interface to create an XML Configuration file for the Silent Brick Connection
# 
# Needs latest FAST.ps1
# Start this Script in order to create a new XML Config File
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)


$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {
    . ("$ScriptDirectory\FAST.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
    exit 0
}
Add-Type -AssemblyName System.Windows.Forms

# Create new Object and load config from XML or create new config via UI
$mycontroller       = New-Object SilentBrick
$configfile         = $mycontroller.CreateConfigfileInteractively()


Write-Host ("Verifying Configfile now")

$mycontroller.StartXMLConfig( $configfile )

### Checking for running tasks
$ret = $mycontroller.getTasksRunning( )


if( $ret -ne $null ){
    write-host "Your Configuration File under $configfile is ready and working. You can now use the config file for a connection. If you want to recreate the file please delete it first an re-run this script."
}
else{
    write-host   = "Verification of the $configfile failed. Please delete the file and retry the configuration."
}



