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


$strCurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name


write-Host @"

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

You are currently connected as: $strCurrentUser

This script will generate a config file, encrypted
with the login credentials of this user "$strCurrentUser". 

If your API calls will later be executed by this user, since this
is your VEEAM Service account or since your Task Scheduler is
running under his credentials, thats fine. 
If not please make sure to run this script with the credentials
of the right user.


"@


$strYesNo = Read-Host "Is $strCurrentUser the user, who will later execute this script actively
or in the background? (Y/N)"

if( $strYesNo -ne "Y" ){
    write-host "Please restart your powershell with the correct user. Thanks"
    exit 1
}

###################################################################
## Start to create the config 


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

Exit-PSSession

