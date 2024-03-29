<#
.SYNOPSIS
   Class Module for Silent Brick API Calls

.DESCRIPTION

    Script to be added to Veeam in order to be executed  before and after the backup.
    It will run in two steps separated by the task parameter. 

    'pre' task:
    - Set target Volume online

    'post' task:
    - Set target Volume offline
 
   For Debugging Purpose set 
        $DebugPreference = "Continue"

.NOTES
    Author: René Weber
    Date:   11.07.2019    

    License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)


    Compatibility: Powershell Version >= 5

.EXAMPLE
    .\VEEAM-WSO_Secure.ps1 -Hostname <Silent Brick System> -Username <Volume Admin> -Password <Password> -Volume <target volume name> -Task <pre or post>

#>

param(
    [string]$Hostname,
    [string]$Username,
    [string]$Password,
    [string]$Volume,
    [string]$Task,
    [String]$Configfile
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
    Write-Host "  -Hostname <hostname or IP>"
    Write-Host "  -Username <username for login>"
    Write-Host "  -Password <password for login>"
    Write-Host " "
    Write-Host "Configfile Authentication:"
    Write-Host "  -Configfile <filename>"
    Write-Host " "
    Write-Host "  -Volume <volume name>"
    Write-Host "  -Task <pre|post> ( Pre will setup replication, post will unlock and eject replica )" 
}

if ( [string]::IsNullOrEmpty( $Task ) -Or [string]::IsNullOrEmpty( $Volume ) -Or [string]::IsNullOrEmpty( $Task )  ){
    help
    exit 1
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


$target_state = "online"

if( $Task -eq "pre")
{
   $target_state = "online"
   
}
elseif( $Task -eq "post"){

     $target_state = "offline"

}
else{
    Write-Error("Invalid Task! Exiting")
    exit 1
}


######################################################
## Lock if needed
if( $Task -eq "pre")
{
   $response = $mycontroller.setVolumeLockByName( $Volume )
}


######################################################
## Set Volume State

$mycontroller.waitForFreeSlot( 150 )

write-debug("Setting Volume to $target_state")

$volDetails = $mycontroller.getVolumeByName( $Volume )
write-debug($volDetails | Format-Table | Out-String )
$status = $volDetails.status

write-debug( "And Status $status")

if( $status -eq $target_state ){
    write-debug("Volume already in state $target_state")
    exit 0
}

if( ! $mycontroller.setVolumeStateByName($Volume, $target_state ) ){
    Write-Error ("Failed to set Volume $target_state!")
    exit 1
}

######################################################
## Wait for the Volume state change


$mycontroller.waitForFreeSlot( 150 )

write-debug("Checking Volume state")

$volDetails = $mycontroller.getVolumeByName( $Volume )
write-debug($volDetails | Format-Table | Out-String )
$status = $volDetails.status

write-debug( "And Status $status")

if ( $status -ne $target_state ){

    $timer = 120

    while( $status -ne $target_state ){
         
         $timeoutcounter--
         if( $timeoutcounter -eq 0 ){
             write-error "Timeout reached! Volume did not switch to $target_state"
             exit 1
        }

        Write-Debug("Still waiting. Status is currently $target_state")
        Start-Sleep -s 2
        $volDetails = $mycontroller.getVolumeByName( $Volume )
        write-debug($volDetails | Format-Table | Out-String )
        $status = $volDetails.status
    }
}


######################################################
## Lock if needed
if( $Task -eq "post")
{
   $mycontroller.waitForFreeSlot( 150 )
   $response = $mycontroller.setVolumeUnlockByName( $Volume )
}

write-debug( "Status successfully set to $status")
exit 0



