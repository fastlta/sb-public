# 
# Author: Rene Weber, FAST LTA GmbH, 2020
#
# Script: Veeam Write Clone Transport
#
# Purpose: 
# Script to be added to Veeam in order to be executed directly after the backup.
# It will run in two processes. 
#
# Pre-Process running before the Backup:
# - Check availability of the target bricks
# - Use as many target bricks as necessary to create a clone
# - Start the replication this/these bricks
#
# Post-Process running after the Backup:
# - Wait for a replication state of 100%
# - Stop the replication
# - Shutdown the copy
# - Label the display
# - Unlock the Bricks
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)


param(
    [string]$Hostname,
    [string]$Username,
    [string]$Password,
    [string]$Volume,
    [string[]]$Targets,
    [string]$Task,
    [string]$TS,
    [String]$Configfile
)


#$DebugPreference = "Continue"


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
    Write-Host "Commandline Authentication:"
    Write-Host "  -Hostname <hostname or IP>"
    Write-Host "  -Username <username for login>"
    Write-Host "  -Password <password for login>"
    Write-Host " "
    Write-Host "Configfile Authentication:"
    Write-Host "  -Configfile <filename>"
    Write-Host " "
    Write-Host "  -Volume <volume name>"
    Write-Host "  -Task <pre|post> ( Pre will setup replication, post will unlock and eject replica )" 
    Write-Host "  -Targets <Comma separated list of Brick Serials to clone to> ( Needed for Task 'pre' )"    
}

if ( [string]::IsNullOrEmpty( $Task ) -Or [string]::IsNullOrEmpty( $Volume ) ){
    help
    exit 1
}
if (  $Task -eq "pre" -And $Targets.count -eq 0 ){
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



###########################################
## Pre-Script : Set up replication
##
if( $Task -eq "pre")
{

        $mycontroller.waitForFreeSlot( 120 )

        ############# Get Volume size ( total ) ########################################

        $objVolume = $mycontroller.getVolumeByName( $Volume )

        if( ! $objVolume -Or ! $objVolume.size  ){
            write-error "Source Volume not found or size invalid"
            exit 1
        }

        $sourceVolumeSize = [double] $objVolume.size
        $sourceVolumeSizeTB = ( $sourceVolumeSize / 1000000000000 )

        Write-Debug ("----  Volume size is: $sourceVolumeSizeTB TB ")

        $sourceVolumeGross =  ([math]::Round( $sourceVolumeSize / 3 ) ) * 4 



        ############# Get targets brick net sizes, availability and usage ########################################

        # Create new Hashtable for our targets
        $targetBricksUsed = @()
        $targetBricksFree = @()

        $allBricks = $mycontroller.getBricks()

        if( $allBricks ){

            $allBricks | foreach-object {
                if( $Targets.Contains( $_.serial ) ){
                    if( $_.unassigned -eq "yes"){
                        $targetBricksFree += ( $_ )
                    }else{
                        $targetBricksUsed += ( $_ )
                    }
                }
            }
        }else{
            Write-Debug "No Bricks found"
        }

        Write-Debug "Found the following free Bricks:"
        Write-Debug ($targetBricksFree | Format-Table | Out-String )

        Write-Debug "Found the following used Bricks:"
        Write-Debug ($targetBricksUsed | Format-Table | Out-String )


        ############# Check if enough free Bricks are available for replication ###################

        # Check against $intNeededSize
        $doubleCalcSize = 0
        $replicateToTargetBricks = @()

        # Collect free bricks until net size matches source volume size 
        foreach ( $_ in $targetBricksFree ) {#
            #$doubleCalcSize += $_.net_capacity
            $doubleCalcSize += $_.gross_capacity
            $replicateToTargetBricks += $_.serial
            $doubleCalcSizeTB = ( $doubleCalcSize / 1000000000000 )
            Write-Debug "---- Bricks found for size $doubleCalcSizeTB  TB "

            if( $doubleCalcSize -ge $sourceVolumeGross ){
                write-debug( "Got enough Bricks to create clone")
                break
            }
        }

         if( $doubleCalcSize -lt $sourceVolumeGross ){
            write-error "Not enough bricks available for cloning"
            exit 1
        }

        write-debug("Will clone to Bricks $replicateToTargetBricks")


        ############# Create replication to target ########################################

        $creation_date = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $strReplVolumeName = "$Volume-copy-$creation_date"

        if( ! $mycontroller.replicateVolume( $Volume, $strReplVolumeName, $replicateToTargetBricks ) ){
            write-error  "Failed to replicate!"
            exit 1
        }

        ############# Store Info about replication in XML File #############################
        if ( Test-Path ".\VEEAM-WCT_Config.xml" ){   
            $VEEAMWCTCONF = Import-Clixml -Path ".\VEEAM-WCT_Config.xml"
        }else{
            $VEEAMWCTCONF = @{}
        }

        $VEEAMWCTCONF.$creation_date = $strReplVolumeName
        $VEEAMWCTCONF | Export-Clixml -Depth 5 -Path ".\VEEAM-WCT_Config.xml"
}

elseif( $Task -eq "post"){

        ############# Get Volume size ( total ) ########################################
        if ( Test-Path ".\VEEAM-WCT_Config.xml" ){   
            $VEEAMWCTCONF = Import-Clixml -Path ".\VEEAM-WCT_Config.xml"
        }else{
            write-error "NO XML Config found! Check for the correct path."
            exit 1
        }

        ##############################################################
        ## Start monitoring for every replication target   
        ## If replication is 100% do: 
        ## - Update Display with latest timestamp
        ## - set offline and unlock 
        ## - Remove from config

        foreach( $timestamp in $VEEAMWCTCONF.keys ){

            Write-Debug("Found replication from $timestamp with the name of "+$VEEAMWCTCONF.$timestamp)
            $ReplVolName = $VEEAMWCTCONF.$timestamp

            start-process PowerShell -NoNewWindow -ArgumentList ".\VEEAM-WCT_Secure.ps1 -Hostname $Hostname -Username $Username -Password $Password -TS $timestamp -Volume $ReplVolName -Task background " -RedirectStandardError .\VEEAM-WCT_Error.log -RedirectStandardOutput .\VEEAM-WCT_Output.log 
          

        }

}
elseif( $Task -eq "background"){

                    $VolumeName = $Volume
                    $timestamp  = $TS
                    #########################
                    ## Get Replication state
                    ## and wait for 100 % progress 

                    $replState = $mycontroller.getReplicationStateByTargetVolumename( $VolumeName )
                    $progress =  [int]$replState.progress

                    $timeoutcounter = 360 # Which is 3 hours with 30 seconds sleep 

                    while( $replState -And $progress -lt 100 ){

                        Start-Sleep -s 30
                        $replState = $mycontroller.getReplicationStateByTargetVolumename( $VolumeName )
                        $progress =  [int]$replState.progress
                        write-debug "Progress is $progress"
                        if( $replState.state -ne "running"){
                            write-error "Replication stopped for unknown reason. Aborting!"
                            exit 1
                        }

                        $timeoutcounter--
                        if( $timeoutcounter -eq 0 ){
                            write-error "Timeout reached! Leaving replication monitor"
                            exit 1
                        }

                    }
                    write-debug "Progress is 100% or already converted"

                    ######################################################
                    ## Update Display of all Bricks with current timestamp

                    $mycontroller.waitForFreeSlot( 150 )

                    $date      = Get-Date -UFormat "%d.%m.%Y"
                    $displaymode = 3
                    $Description = "Clone $date"
                    $Bricks = $mycontroller.getBricksByVolumeName( $VolumeName)

                    Write-Debug "Received $Bricks"

                    $Bricks | foreach {
                        
                        $displayret = $mycontroller.updateBrickDescription( $_, $Description, $Displaymode )
                        if ( $displayret ){
                            Write-Debug "Successfully updated Display for $_."
                        }
                        else{
                             Write-Error "Display update failed for $_."
                        }

                    }


                    ######################################################
                    ## Convert replication to standard volume
                    
                    $mycontroller.waitForFreeSlot( 150 )

                    write-debug("Converting Replication")
                    if( $replState -And ! $mycontroller.convertReplication( $VolumeName ) ){
                        write-error ( "Convertion failed!")
                    }


                    ######################################################
                    ## Set Volume offline

                    $mycontroller.waitForFreeSlot( 150 )

                    write-debug("Checking Volume state")

                    $volDetails = $mycontroller.getVolumeByName( $VolumeName )
                    write-debug($volDetails | Format-Table | Out-String )
                    $status = $volDetails.status

                    write-debug( "And Status $status")
    
                    if ( $status -ne "offline" ){

                        $timer = 60

                        while( $status -ne "online" -And $status -ne "offline" ){
                             
                             $timeoutcounter--
                             if( $timeoutcounter -eq 0 ){
                                 write-error "Timeout reached! Volume did not switch to online mode"
                                 exit 1
                            }
                            Write-Debug("Still waiting. Status is currently $status")
                            Start-Sleep -s 2
                            $volDetails = $mycontroller.getVolumeByName( $VolumeName )
                            write-debug($volDetails | Format-Table | Out-String )
                            $status = $volDetails.status
                        }
                    }
                    if ( $status -eq "online" ){
                        write-debug("Setting Volume offline now")
                        $mycontroller.setVolumeStateByName($VolumeName, "offline" ) 
                    }


                    ######################################################
                    ## Set Bricks to unlock
                    
                    $mycontroller.waitForFreeSlot( 150 )

                    write-debug("Unlocking Bricks")
                    if( ! $mycontroller.setVolumeUnlockByName( $VolumeName ) ){
                        write-error "Failed to unlock bricks"
                    }

                    ######################################################
                    ## Update XML
                     if ( Test-Path ".\VEEAM-WCT_Config.xml" ){   
                            $VEEAMWCTCONF = Import-Clixml -Path ".\VEEAM-WCT_Config.xml"
                    }else{
                        write-error "Failed to Update xml"
                        exit 1
                    }
                    
                    $OUTPUT = @{}
                    foreach( $t in $VEEAMWCTCONF.keys ){
                        if( $t -ne $timestamp ){
                            $OUTPUT.add( $t, $VEEAMWCTCONF.$t)
                        }
                    }
                   
                    $OUTPUT | Export-Clixml -Depth 5 -Path ".\VEEAM-WCT_Config.xml"
}

exit 0

