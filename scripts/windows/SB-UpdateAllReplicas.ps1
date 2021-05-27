# 
# Author: Rene Weber, FAST LTA AG, 2021
#
# Script: UpdateAllReplicas
#
# Purpose: Provide a Windows Script sample to update the state of all replicas for a given source volume
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)
#
# Version: 1.2



param(
    [string]$Hostname,
    [string]$Username,
    [string]$Password,
    [String]$Volume,
    [String]$Configfile,
    [String]$Set
)


$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {
    . ("$ScriptDirectory\FAST.ps1")
}
catch {
    Write-Error "Error while loading supporting PowerShell Scripts" 
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
    Write-Host "  -Set <offline|online>"
    exit 
}


if ( [string]::IsNullOrEmpty( $Volume ) ){
   help
}

if ( [string]::IsNullOrEmpty( $Set ) ){
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


# Get Volume ID 
$strVolumeID = $mycontroller.getVolumeIDByName( $Volume )

# Get all replication target volumes 
if( ! ( $objReplicationTargets = $mycontroller.getReplicationsByVolumeID( $strVolumeID) ) ){
    write-error "Failed to retrieve replicas"
    exit
}

#Write-Host ($objReplicationTargets | Format-Table | Out-String )

# Get all voluems 
if( ! ( $allVolumes = $mycontroller.getVolumes() ) ) {
    write-error "Failed to list volumes"
    exit
}

#Write-Host ($allVolumes | Format-Table | Out-String )


# Iterate through replicas and change volume state 

$objReplicationTargets | foreach-object { 

    ######################################################
    ## Get Current Volume State

    $mycontroller.waitForFreeSlot( 150 )
    $stringCurVolState = $mycontroller.getVolumeStateByID(  $_.target_volume_uuid )

    if( ! $stringCurVolState ){
        write-host "Failed to get current volume state for $_.target_volume_uuid - ignoring"
        continue
    }

    if( $Set -eq "offline" -And $stringCurVolState -eq "online" ){


        ######################################################
        ## Set Volume Offline Bricks
        
        $mycontroller.waitForFreeSlot( 150 )
        if( ! $mycontroller.setVolumeState( $_.target_volume_uuid , "offline" ) ){
            write-error "Failed to set replica offline"
        }

        ######################################################
        ## Unlock Bricks
                        
        $mycontroller.waitForFreeSlot( 150 )

        write-debug("Unlocking Bricks")
        if( ! $mycontroller.setVolumeUnlock( $_.target_volume_uuid ) ){
            write-error "Failed to unlock bricks"
        }

    }elseif( $Set -eq "online" -And $stringCurVolState -eq "offline" ){

        ######################################################
        ## Set Volume Online 
        
        $mycontroller.waitForFreeSlot( 150 )
        if( ! $mycontroller.setVolumeState( $_.target_volume_uuid , "online" ) ){
            write-error "Failed to set replica online"
        }

    }else{
        write-host "Ignoring "  $_.target_volume_uuid  "  - can not set to $Set in current state ($stringCurVolState)"
    }
  
  
}
