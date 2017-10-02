# 
# Author: Joerg Juenger, FAST LTA AG, 2017
#
# Script: GetVolumeInfos
#
# Purpose: Provide a Windows Script sample how to collect information from the public API of
#          the FAST LTA AG Silent Bricks System
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)

# inital values to adjust for the connection to the SB controllers
# Change these to adress your controller.s
#$strIP = "192.168.13.10" ##"172.100.51.222"
#$strUser = "monitoring"  ##"joerg_ro"
#$strPwd = "abc123"       ##"jjtest"
$strIP = "172.100.51.35"
$strUser = "joerg_ro"
$strPwd = "jjtest"


# adjust the debugging level
# for more info see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-psdebug?view=powershell-5.1
## set to -Off in case no debg output wanted
## set to -Strict in case debg output wanted
Set-PSDebug -Strict
$ErrorActionPreference = "Continue"
$Error.Clear()
$VerbosePreference="Continue"

# make sure the secure conection works.
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null

# prepare the request
$secVolInfoURL = "https://" + $strIP + "/sb-public-api/api/v1/volumes.json"
$dictAuth = @{"AUTHORIZATION"="Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($strUser+":"+$strPwd ))}
$dictAuth.Add("cache-control", "no-cache")
$dictAuth.Add("Content-Type","application/json")

try {
    
    $response = Invoke-WebRequest -Uri $secVolInfoURL -Headers $dictAuth -Method Get -UseBasicParsing
    
    write-host "     ----- Headers"
    write-host $response.Headers
    write-host "     ----- Volumes"

    $volumesObj = ConvertFrom-Json -InputObject $response.Content

    # print the volume infos first
    $volumesObj | foreach-object { 
        write-host $_
    }

    # fetch the volumes partitions infos now
    $volumesObj | foreach-object { 
        $strVolumeID =  $_.uuid
        if (! [string]::IsNullOrEmpty($strVolumeID)) {
            GetPartitionsInfo $strVolumeID
        }
    }

} catch [Exception] {
    ExceptionOutput $_.Exception
}

# get and output partitions info of a given volume
function GetPartitionsInfo ([String]$strVolumeID) 
{
    try {
        $secVolumeURL = "https://" + $strIP + "/sb-public-api/api/v1/volumes/" + $strVolumeID + "/partitions.json"
        
        $response = Invoke-WebRequest -Uri $secVolumeURL -Headers $dictAuth -Method Get -UseBasicParsing
    
        $volInfo =  "     ----- Partitions of volume " + $strVolumeID
        write-host $volInfo

        $partitionsObj = ConvertFrom-Json -InputObject $response.Content

        # print the partitions infos now
        $partitionsObj | foreach-object { 
            write-host $_
        }

    } catch [Exception] {
        ExceptionOutput $_.Exception
    }
}

# console output function for a given Exception object
function ExceptionOutput ([Exception]$excp)
{
    write-host "---- Exception Information ----"
    write-host $excp.GetType().FullName; 
    $msg = $excp.Message
    while ($excp.InnerException) {
        $excp = $excp.InnerException
        $msg += "`n" + $excp.Message
    }
    write-host $msg
    write-host $excp.Stacktrace;
    write-host $excp.FullyQualifiedErrorId;
}

