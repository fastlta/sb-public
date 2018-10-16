# 
# Author: Rene Weber, FAST LTA AG, 2017
#
# Script: GetSnapshots
#
# Purpose: Provide a Windows Script sample how to collect information from the public API of
#          the FAST LTA AG Silent Bricks System
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)


# Set SSL Protocol
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

# Ignore SSL Certificate
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


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



Class SilentBrick
{

    [String] $IP        
    [String] $User      
    [String] $Password
    [Object] $dictAuth

    # Basic GET API Request
    # Param: Uri, last part after api/v1/
    # Returns: Object with result or empty Object
    [Object] executeGetRequest ([String]$strUri) 
    {

        # Build Authentication Header
        $this.dictAuth = @{"AUTHORIZATION"="Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($this.User+":"+$this.Password ))}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")

        $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/"+$strUri
        write-host "Using $strUri"
         try {
            
            
            $response = Invoke-WebRequest -Uri $strUri -Headers $this.dictAuth -Method GET -UseBasicParsing
        
            $retObj = ConvertFrom-Json -InputObject $response.Content

            return $retObj

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return $null
        }
    }

    # Basic GET API Request
    # Param: Uri, last part after api/v1/
    #        Dictionary for the Payload
    # Returns: Object with result or empty Object
    [Object] executePutRequest ([String]$strUri, [PSCustomObject] $dictPayload) 
    {

        # Build Authentication Header
        $this.dictAuth = @{"AUTHORIZATION"="Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($this.User+":"+$this.Password ))}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")

         $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/"+$strUri
        write-host "Using $strUri"
         try {
            
            
            $response = Invoke-WebRequest -Uri $strUri -Headers $this.dictAuth -Method PUT -UseBasicParsing -Body $dictPayload  -ContentType "application/x-www-form-urlencoded"
            $retObj = ConvertFrom-Json -InputObject $response.Content

            return $retObj

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return $null
        }
    }

    # Basic GET API Request
    # Param: Uri, last part after api/v1/
    #        Dictionary for the Payload
    # Returns: Object with result or empty Object
    [Object] executeDeleteRequest ([String]$strUri ) 
    {

        # Build Authentication Header
        $this.dictAuth = @{"AUTHORIZATION"="Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($this.User+":"+$this.Password ))}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")

        $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/"+$strUri
        write-host "Using $strUri"
        try {
            
            
            $response = Invoke-WebRequest -Uri $strUri -Headers $this.dictAuth -Method DELETE -UseBasicParsing -ContentType "application/x-www-form-urlencoded"
            $retObj = ConvertFrom-Json -InputObject $response.Content

            return $retObj

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return $null
        }
    }

    # get and output partitions info of a given volume
    [Object] getPartitionsByVolumeID ([String]$strVolumeID) 
    {
        try {
            $strEndpoint = "volumes"
            $strTask = "partitions"

            $URL = "$strEndpoint/$strVolumeID/$strTask"+".json"
            
            $response = $this.executeGetRequest( $URL )
            return $response.partitions

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return $null
        }
    }

   # get and output partitions info of a given volume
    [Object] getVolumes () 
    {
        try {
            $strEndpoint = "volumes"

            $URL = "$strEndpoint"+".json"
            
            $response = $this.executeGetRequest( $URL )
            return $response.volumes

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return $null
        }
    }

    # Translate a Volume Name to a Volume ID
    [String] getVolumeIDByName ([String]$strVolumeName)
    {
         try {

            $strEndpoint = "volumes"

            $strURL = "$strEndpoint"+".json"
            
            $response = $this.executeGetRequest( $strURL )

            $strVolumeIDReturn = $null

            # fetch the volumes partitions infos now
            $response.volumes | foreach-object { 
                $objVolume = $_
                    if (! [string]::IsNullOrEmpty($objVolume.name) -And $objVolume.name  -eq $strVolumeName ) {
                       $strVolumeIDReturn = $objVolume.uuid
                    }
            }
            return $strVolumeIDReturn

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return $null
        }
    }

    # get and output partitions info of a given volume
    # Type may be all, error, info, warning
    [Object] getOpenIssues ([String]$type) 
    {
        try {

            $strEndpoint = "open_issues"

            $strURL = $strEndpoint+".json"
            
            $response = $this.executeGetRequest( $strURL )
            write-host $response
            return $response.partitions

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return $null
        }
    }


    # Create a snapshot with the given name
    # Param String Volume ID
    #       String Snapshot Name
    #       String Description
    # Returns 1 for succes, 0 for false
    [int] createSnapshot ( [String]$strVolumeID, [String]$strSnapshotName, [String]$strDescription )
    {
        $intRet = 1

         try {

            $strEndpoint = "volumes"
            $strTask     = "snapshot"

            $strURL = $strEndpoint+".json"
            $strURL = "$strEndpoint/$strVolumeID/$strTask"+".json"

            # Create Payload for a PUT Request
            $dictPayload = @{}
            $dictPayload.Add('name', $strSnapshotName)
            $dictPayload.Add('description', $strDescription)

            if( $this.executePutRequest( $strURL, $dictPayload ) ){
                return 1
            }

            return 0

            

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return 0

        }
    }


     # get and output partitions info of a given volume
    [Object] getSnapshotsByVolumeID ([String]$strVolumeID) 
    {
        try {
            $strEndpoint = "volumes"
            $strTask = "list_snapshots"

            $URL = "$strEndpoint/$strVolumeID/$strTask"+".json"
            
            $response = $this.executeGetRequest( $URL )
            return $response.snapshots

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return $null
        }
    }
    # get and output partitions info of a given volume
    [int] deleteSnapshotByID ([String]$strSnapshotID) 
    {


        try {
            $strEndpoint = "snapshots"
           

            $URL = "$strEndpoint/$strSnapshotID"+".json"
            
        
            if( $this.executeDeleteRequest( $URL ) ){
                return 1
            }
            
            return 0
           

        } catch [Exception] {
            ExceptionOutput $_.Exception
            return 0
            
        }
        

    }

}






