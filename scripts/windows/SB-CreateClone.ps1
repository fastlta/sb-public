# 
# Author: Rene Weber, FAST LTA GmbH, 2020
#
# Script: CreateClone
#
# Purpose: Provide a Windows Script sample of how to create a Volume clone with the public API of
#          the FAST LTA AG Silent Bricks System
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)





param(
    [string]$Hostname,
    [string]$Username,
    [string]$Password,
    [string]$Volume,
    [String[]]$Bricks,
    [int]$Eject,
    [int]$Display,
    [String]$Configfile
)


$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {
    . ("$ScriptDirectory\FAST.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
    exit 0
}

$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()



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
    Write-Host "  -Bricks <Commaseparated list of target brick serials. Minumum 1 Brick>"
    Write-Host "  -Display <1|0> | Update Display of all target Bricks to timestamp"
    Write-Host "  -Eject <1|0> | Forces Eject after completion"
    exit 
}


if ( [string]::IsNullOrEmpty( $Bricks ) -Or [string]::IsNullOrEmpty( $Volume )  ){
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



### Checking for running tasks
$ret = $mycontroller.getTasksRunning( )


if( $ret ){
    Write-Host "Communication succeeded. Target is busy."
}
else{
    Write-Host "Communication succeeded. Target waiting for tasks."
}


#####
# CREATE CLONE 
#####

$ret = $mycontroller.cloneVolume(
        $Volume,
        "$Volume-Clone-$timestamp",
        $Bricks
    )

if( $ret -ne 1 ){
    write-host "Failed to create Clone!"
    exit
}
else{

    #####
    # If cloning succeeded update Epaper Display - forked
    #####

    if ( $Display -eq 1 ){

        # This Block should be started in background actually with a Testloop
        # instead of a fixed 10 seconds of sleep
        # Problems herewith:
        #  All Object are deserialized and must be recreated    
        #  Including the FAST.ps1 did not succeed for background tasks
        
        write-host "Starting Job to Update Brick Displays in 10 seconds"

        # Need have a break here in order to wait for the last job to finish....
        Start-Sleep -s 10

        $date      = Get-Date -UFormat "%d.%m.%Y"
        $time      = Get-Date -UFormat "%h.%M"
        $displaymode = 3
        $Description = "Clone $date"
        $Bricks | foreach {
            
            $displayret = $mycontroller.updateBrickDescription( $_, $Description, $Displaymode )
            if ( $displayret ){
                Write-Host "Successfully updated Display for $_."
            }
            else{
                 Write-Error "Display update failed for $_."
            }

        }

    }
    

    # If cloning succeeded fork a process to set brick offline ( and eject )

    if ( $Display -eq 1 ){
            write-error "Sorry. This function is not yet available"
            #Start-Job -Name SetDisplay -ScriptBlock {
            #    param( [String]$Hostname, [String]$Username, [String]$Password, [String[]]$Bricks, [String]$ScriptDirectory)

            #} -ArgumentList( $Hostname, $Username, $Password, $Bricks, $ScriptDirectory ) 
    }
}