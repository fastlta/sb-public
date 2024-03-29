<#
.SYNOPSIS
   Class Module for Silent Brick API Calls

.DESCRIPTION

    Veeam Rotated Harddisk Secutiry
    Script to be executed by an independent task manager within a seperate Management Network.
    The idea of this script is to set the current backup target offline - so it can not be attacked anymore - 
    and to switch the share to a next volume instead. 
    In combination with the continuous snapshot feature and the Veeam Option "Rotated Harddrives" you can
    create a sample setup as follows:

    Write Backups to "Volume 1"
    Secure "Volume 1" against modification using the continuous Snapshot feature for up to 30 days
    In order to extend security, switch the volume offline after this period of time
    Remove the share
    Start up "Volume 2"
    Add the Share
    
    Next Backup run will now adress "Volume 2" as backup to disk repository. According to the Veeam Feature
    "Rotated Harddrives" a new Full Backup Chain will now be started.

    Optional: Erase Volume B before startup. 
 
   For Debugging Purpose set 
        $DebugPreference = "Continue"

.NOTES
    Author: René Weber
    Date:   16.11.2023    

    License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)


    Compatibility: Powershell Version >= 5

.EXAMPLE
    .\VEEAM-RHR_Secure.ps1 -Hostname <Silent Brick System> -Username <Volume-Admin> -Password <Password> -VolumePrefix <target volume name prefix>

#>

param(
    [string]$Hostname,
    [string]$Username,
    [string]$Password,
    [String]$Configfile,
    [String]$VolumePrefix,
    [String]$ShareName,
    [Int]$Unlock
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
    Write-Host "  -VolumePrefix <Prefix of Volumes to be used. i.e. 'Rotated-'>"
    Write-Host "  -ShareName  <name of the share to be cycled>"
    Write-Host "  -Unlock  <1 or 0 >"
   }


if ( [string]::IsNullOrEmpty( $VolumePrefix ) -Or [string]::IsNullOrEmpty( $ShareName ) ){
    help
    exit 1
}

if ( [string]::IsNullOrEmpty( $Unlock )){
    $Unlock = 0
}

######################################################
## Initialize Silent Brick Connection

$mycontroller = New-Object SilentBrick


if( -Not [string]::IsNullOrEmpty( $Configfile ) ){
    $mycontroller.StartXMLConfig( $Configfile )

}elseif( -Not ( [string]::IsNullOrEmpty( $Username ) -Or [string]::IsNullOrEmpty( $Password ) ) ){
    $mycontroller.IP = $Hostname
    $mycontroller.User = $Username
    $mycontroller.Password = $Password
}else{
    help
    exit 1
}


############################################################
## Create list of all Volumes matching Prefix $VolumePrefix

$arrVolumesForRotation = @();


# Read Volumes
$objVolumes     = $mycontroller.getVolumes()

Write-debug "----- All Volumes "
Write-debug ($objVolumes | Format-Table | Out-String )

# Create array of Volumes matching prefix and type "nas"
$objVolumes | foreach-object { 

    $strVolumeID =  $_.uuid
    if (! [string]::IsNullOrEmpty($strVolumeID)) {
        $objPartitions = $mycontroller.getPartitionsByVolumeID( $strVolumeID )
        if( $_.name.startsWith( $VolumePrefix )  -And $_.nas_engine -Like "nas" ){
            Write-Debug ( "$_.name  matches  $VolumePrefix  and  $_.nas_engine  matches nas")
            Write-Debug ($objPartitions | Format-Table | Out-String )
            Write-Debug("Adding to array: " + $_.name)
            $arrVolumesForRotation += $_.name;
        }else{
            Write-Debug ( "$_.name  does not match  $VolumePrefix  or  $_.nas_engine  does not match snas")
        }
    }
}

# Sort the array to avoid random assignment
[array]::sort($arrVolumesForRotation)

write-Debug($arrVolumesForRotation | Format-Table | Out-String )



######################################################
## Get Volumename with assigned sharename $sharename 
## and match it to our array. If no match, good bye.


# Get Share details with this the name $ShareName
$objShare     = $mycontroller.getShareByName($ShareName)

if( -not $objShare -Or $objShare.fstype -like "sss"){
    Write-Error "No Share with name $ShareName found or unsupported S3"
    exit 1
}
Write-Debug ($objShare | Format-Table | Out-String )

$objAssignedVolume      = $mycontroller.getVolumeByID( $objShare.volume_uuid)
$strAssignedVolumeName  = $objAssignedVolume.name



######################################################
## Get next volume, our share should be assigned to 

# Get Index of Volume in our array $arrVolumesForRotation 
# our share is assigend to right now. 
$intIndex = $arrVolumesForRotation.IndexOf($strAssignedVolumeName)

if( $intIndex -lt 0){
    Write-Error( "Share not assigned to an volume matching the prefix.")
    exit 1
}
Write-Debug("Found $ShareName assigned to $strAssignedVolumeName which is position " + ($intIndex+1) + " in array of length " + $arrVolumesForRotation.Length )

$intNextIndex=0
if( ($intIndex+1) -ne $arrVolumesForRotation.Length ){
    $intNextIndex = $intNextIndex+1
}

$strNextVolumeName = $arrVolumesForRotation[$intNextIndex]
 

Write-Host("Your share is currently assigend to " + $strAssignedVolumeName)
Write-Host("In the next step it will be assigend to " + $strNextVolumeName)


######################################################
## Set Volume online if it is not

$volDetails = $mycontroller.getVolumeByName( $strNextVolumeName )
write-debug($volDetails | Format-Table | Out-String )
$status = $volDetails.status

write-debug( "Your target Volume is in state  $status")

if( $status -eq "online" ){
    write-debug("Volume already in state online")
}elseif( ! $mycontroller.setVolumeStateByName($strNextVolumeName, "online" ) ){
    Write-Error ("Failed to set Volume online!")
    exit 1
}else{

  ## Wait for the Volume state change
    $mycontroller.waitForFreeSlot( 150 )

    write-debug("Checking Volume state")

    $volDetails = $mycontroller.getVolumeByName( $strNextVolumeName )
    write-debug($volDetails | Format-Table | Out-String )
    $status = $volDetails.status

    write-debug( "Status is $status")

    if ( $status -ne "online" ){

        $timer = 300

        while( $status -ne "online" ){
             
             $timeoutcounter--
             if( $timeoutcounter -eq 0 ){
                 write-error "Timeout reached! Volume did not switch to online"
                 exit 1
            }

            Write-Debug("Still waiting. Status is currently online")
            Start-Sleep -s 2
            $volDetails = $mycontroller.getVolumeByName( $strNextVolumeName )
            write-debug($volDetails | Format-Table | Out-String )
            $status = $volDetails.status
        }
    }

}


######################################################
## Delete old share

if( ! $mycontroller.deleteShareByID( $objShare.uuid) ){
    Write-Error("Failed to remove share from $strAssignedVolumeName. Please move it manually or retry.")
    exit 1
}

######################################################
## Add new share

if( ! $mycontroller.addSMBShare($mycontroller.getVolumeIDByName( $strNextVolumeName ), $objShare) ){
    Write-Error("Failed to add the share to $strNextVolumeName. Please create it manually.")
    exit 1
}

######################################################
## Set previous Volume offline and unlock

## Exit if Flag was not set.
if( $Unlock -ne 1){
    Write-Host "Done. "
    exit 0
}


$volDetails = $mycontroller.getVolumeByName( $strAssignedVolumeName )
$status = $volDetails.status

write-debug( "And Status $status")
if ( $status -ne "offline" ){

    $timer = 300

    while( $status -ne "online" -And $status -ne "offline" ){
         
         $timeoutcounter--
         if( $timeoutcounter -eq 0 ){
             write-error "Timeout reached! Volume did not switch to online mode"
             exit 1
        }
        Write-Debug("Still waiting. Status is currently $status")
        Start-Sleep -s 2
        $volDetails = $mycontroller.getVolumeByName( $strAssignedVolumeName )
        write-debug($volDetails | Format-Table | Out-String )
        $status = $volDetails.status
    }
}
if ( $status -eq "online" ){
    write-debug("Setting Volume offline now")
    if( ! $mycontroller.setVolumeStateByName($strAssignedVolumeName, "offline" ) ){
        Write-Error "Failed to set Volume offline."
        exit 1
    } 
}

############################################
## Unlock Silent Bricks 

$mycontroller.waitForFreeSlot( 150 )

write-debug("Unlocking Bricks")
if( ! $mycontroller.setVolumeUnlockByName( $strAssignedVolumeName ) ){
    write-error "Failed to unlock bricks"
    exit 1
}

exit 0


