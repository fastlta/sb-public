# 
# Author: Rene Weber, FAST LTA AG, 2018
#
# Script: Veeam Write Clone Transport
#
# Purpose: 
# Script to be added to Veeam in order to be executed directly after the backup.
# It will 
# - Check availability of the target bricks
# - Use as many target bricks as necessary to create a copy
# - Create a copy to this/these bricks
# 
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)


param(
    [string]$Hostname,
    [string]$Username,
    [string]$Password,
    [string]$Volume,
    [string[]]$Targets,
    [string]$Task
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
    Write-Host "  -Hostname <hostname or IP>"
    Write-Host "  -Username <username for login>"
    Write-Host "  -Password <password for login>"
    Write-Host "  -Volume <volume name>"
    Write-Host "  -Task <pre|post> ( Pre will setup replication, post will unlock and eject replica )" 
    Write-Host "  -Targets <Comma separated list of Brick Serials to clone to> ( Needed for Task 'pre' )"    
}

if ( [string]::IsNullOrEmpty( $Task ) -Or [string]::IsNullOrEmpty( $Hostname ) -Or [string]::IsNullOrEmpty( $Username ) -Or [string]::IsNullOrEmpty( $Password ) -Or [string]::IsNullOrEmpty( $Volume ) ){
    help
    exit 
}
if (  $Task -eq "pre" -And $Targets.count -eq 0 ){
    help
    exit
}



write-debug "Hostname is $Hostname, User is $Username, Pass is $Password"



$mycontroller = New-Object SilentBrick

$mycontroller.IP = $Hostname
$mycontroller.User = $Username
$mycontroller.Password = $Password

###########################################
## Pre-Script : Set up replication
##
if( $Task -eq "pre")
{


        ############# Get Volume size ( total ) ########################################

        $objVolume = $mycontroller.getVolumeByName( $Volume )

        if( ! $objVolume -Or ! $objVolume.used  ){
            write-error "Source Volume not found or size invalid"
            exit 0
        }

        $sourceVolumeSize = [double] $objVolume.size
        $sourceVolumeSizeTB = ( $sourceVolumeSize / 1000000000000 )

        Write-Debug ("----  Volume size is: $sourceVolumeSizeTB TB ")



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
        foreach ( $_ in $targetBricksFree ) {
            $doubleCalcSize += $_.net_capacity
            $replicateToTargetBricks += $_.serial
            $doubleCalcSizeTB = ( $doubleCalcSize / 1000000000000 )
            Write-Debug "---- Bricks found for size $doubleCalcSizeTB  TB "

            if( $doubleCalcSize -ge $sourceVolumeSize ){
                write-debug( "Got enough Bricks to create clone")
                break
            }
        }

         if( $doubleCalcSize -lt $sourceVolumeSize ){
            write-error "Not enough bricks available for cloning"
            exit 0
        }

        write-debug("Will clone to Bricks $replicateToTargetBricks")


        ############# Create replication to target ########################################

        $creation_date = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $strReplVolumeName = "$Volume-copy-$creation_date"

        if( ! $mycontroller.replicateVolume( $Volume, $strReplVolumeName, $replicateToTargetBricks ) ){
            write-error  "Failed to replicate!"
            exit 0
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

if( $Task -eq "post"){

        ############# Get Volume size ( total ) ########################################
        if ( Test-Path ".\VEEAM-WCT_Config.xml" ){   
            $VEEAMWCTCONF = Import-Clixml -Path ".\VEEAM-WCT_Config.xml"
        }else{
            write-error "NO XML Config found! Check for the correct path."
            exit 0 
        }

        ##############################################################
        ## Start monitoring for every replication target   
        ## If replication is 100% do: 
        ## - Update Display with latest timestamp
        ## - set offline and unlock 
        ## - Remove from config

        foreach( $timestamp in $VEEAMWCTCONF.keys ){

            Write-Debug("Found replication from $timestamp with the name of "+$VEEAMWCTCONF.$timestamp)

            
            ###################### 
            # Start Background Job 
                        
            Start-Job -Name MonitorReplication  -Init ([ScriptBlock]::Create("Set-Location '$pwd'"))  -ScriptBlock {
                param( [String]$Hostname, [String]$Username, [String]$Password, [String]$VolumeName, [string] $timestamp  )

                   

                    try {
                        . (".\FAST.ps1")
                    }
                    catch {
                        Write-Host "Error while loading supporting PowerShell Scripts" 
                        exit 0
                    }


                    $mycontroller = New-Object SilentBrick

                    $mycontroller.IP = $Hostname
                    $mycontroller.User = $Username
                    $mycontroller.Password = $Password

                    Write-Host "Doing things with $VolumeName"

                    #########################
                    ## Get Replication state
                    ## and wait for 100 % progress 

                    $replState = $mycontroller.getReplicationStateByTargetVolumename( $VolumeName )
                    $progress =  [int]$replState.progress

                    $timeoutcounter = 360 # Which is 3 hours with 30 seconds sleep 

                    while( $progress -lt 100 ){

                        Start-Sleep -s 30
                        $replState = $mycontroller.getReplicationStateByTargetVolumename( $VolumeName )
                        $progress =  [int]$replState.progress
                        write-debug "Progress is $progress"
                        if( $replState.state -ne "running"){
                            write-error "Replication stopped for unknown reason. Aborting!"
                            exit 0
                        }

                        $timeoutcounter--
                        if( $timeoutcounter -eq 0 ){
                            write-error "Timeout reached! Leaving replication monitor"
                            exit 0
                        }

                    }
                    write-debug "Progress is 100% now"

                    ######################################################
                    ## Update Display of all Bricks with current timestamp

                    $date      = Get-Date -UFormat "%d.%m.%Y"
                    $displaymode = 3
                    $Description = "Clone $date"
                    $Bricks = $mycontroller.getBricksByVolumeName( $VolumeName)
                    Write-Host "Received $Bricks"
                    $Bricks | foreach {
                        
                        $displayret = $mycontroller.updateBrickDescription( $_, $Description, $Displaymode )
                        if ( $displayret ){
                            Write-Host "Successfully updated Display for $_."
                        }
                        else{
                             Write-Error "Display update failed for $_."
                        }

                    }


                    ######################################################
                    ## Convert replication to standard volume
                    
                    write-debug("Converting Replication")
                    if( !  $mycontroller.convertReplication( $VolumeName ) ){
                        write-error ( "Convertion failed!")
                        exit 0
                    }


                    ######################################################
                    ## Set Volume offline

                    write-debug("Setting Volume offline")
                    $volume = $mycontroller.getVolumeByName( $VolumeName )
                    if ( $volume.status -eq "online" ){
                        $mycontroller.setVolumeStateByName($VolumeName, "offline" ) 
                    }


                    ######################################################
                    ## Set Bricks to unlock
                    
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
                    write-host( $OUTPUT| Format-Table | Out-String )
                    $OUTPUT | Export-Clixml -Depth 5 -Path ".\VEEAM-WCT_Config.xml"
                    


            } -ArgumentList( $mycontroller.IP, $mycontroller.User, $mycontroller.Password, $VEEAMWCTCONF.$timestamp, $timestamp ) 


        }

}





