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
    [string[]]$Targets
)


$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {
    . ("$ScriptDirectory\FAST.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
    exit 0
}


if ( [string]::IsNullOrEmpty( $Hostname ) -Or [string]::IsNullOrEmpty( $Username ) -Or [string]::IsNullOrEmpty( $Password ) -Or [string]::IsNullOrEmpty( $Volume ) -Or $Targets.count -eq 0 ){
    Write-Host "Parameters needed:"
    Write-Host "  -Hostname <hostname or IP>"
    Write-Host "  -Username <username for login>"
    Write-Host "  -Password <password for login>"
    Write-Host "  -Volume <volume name>"
    Write-Host "  -Targets <Comma separated list of Brick Serials to clone to>"
    exit 
}

write-debug "Hostname is $Hostname, User is $Username, Pass is $Password"



$mycontroller = New-Object SilentBrick

$mycontroller.IP = $Hostname
$mycontroller.User = $Username
$mycontroller.Password = $Password


############# Get Volume details ########################################

$objVolume = $mycontroller.getVolumeByName( $Volume )

if( ! $objVolume -Or ! $objVolume.used  ){
    write-error "Source Volume not found or size invalid"
    exit 0
}

$intNeededSize = [int] $objVolume.used

Write-Debug "Needed size is: $intNeededSize"



############# Get Bricks used by Volume ########################################



############# Get targets sizes, availability and usage ########################################

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
    Write-Host "No Bricks found"
}

Write-Host "Free Bricks:"
Write-Host ($targetBricksFree | Format-Table | Out-String )

Write-Host "Used Bricks:"
Write-Host ($targetBricksUsed | Format-Table | Out-String )


############# Check if enough free Bricks are available for cloning ###################

# Check against $intNeededSize
$intCalcSize = 0
$cloneTargetBricks = @()

foreach ( $_ in $targetBricksFree ) {
    $intCalcSize += $_.net_capacity
    $cloneTargetBricks += $_.serial
    Write-Debug(" Size is now $intCalcSize ")

    if( $intCalcSize -gt $intNeededSize ){
        write-debug( "Got enough Bricks to create clone")
        break
    }
}

 if( $intCalcSize -lt $intNeededSize ){
    write-error "Not enough bricks available for cloning"
    exit 0
}

write-debug("Will clone to Bricks $cloneTargetBricks")


############# Create clone to target ########################################

$creation_date = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$strCloneVolumeName = "$Volume-clone-$creation_date"

$mycontroller.cloneVolume( $Volume, $strCloneVolumeName, $cloneTargetBricks ) 







