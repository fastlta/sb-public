<#
.SYNOPSIS
   Class Module for Silent Brick API Calls

.DESCRIPTION
   This Class module may be used for various Powershell Scripts and supports calls for many different API commands.
    
   For Debugging Purpose set 
        $DebugPreference = "Continue"

.NOTES
    Author: René Weber
    Date:   17.10.2018    

    License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)
    
    For Debugging Purpose set 
        $DebugPreference = "Continue"


.EXAMPLE
    ./FAST.ps1

    $mycontroller = New-Object SilentBrick

    $mycontroller.IP = $Hostname
    $mycontroller.User = $Username
    $mycontroller.Password = $Password

    $mycontroller.<method>

#>


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
     $msg = $excp.Message
     while ($excp.InnerException) {
         $excp = $excp.InnerException
         $msg += "`n" + $excp.Message
     }
     write-debug( $excp )
     throw $msg
}


Class SilentBrick
{


    [String] $IP        
    [String] $User      
    [String] $Password
    [Object] $dictAuth
    [String] $osversion
    [int] $checkTasksFirst = 1



     <# -------------------- GENERIC METHODS -------------------- #> 
    # Basic GET API Request
    # Param: Uri, last part after api/v1/
    # Returns: Object with result or empty Object
    [Object] executeGetRequest ([String]$strUri) 
    {

        if ( !$this.waitForFreeSlot(10) ){
            Write-Error "System is not ready. Aborting"  -ErrorAction Stop
            return $null;
        }

        # Build Authentication Header
        $this.dictAuth = @{"AUTHORIZATION"="Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($this.User+":"+$this.Password ))}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")

        $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/"+$strUri
        Write-Debug "Using $strUri"
         try {
            
            
            $response = Invoke-WebRequest -Uri $strUri -Headers $this.dictAuth -Method GET -UseBasicParsing
        
            $retObj = ConvertFrom-Json -InputObject $response.Content

            return $retObj

        } catch [System.Net.WebException] { 
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


        if ( !$this.waitForFreeSlot(10) ){
            Write-Error "System is not ready. Aborting"  -ErrorAction Stop
            return $null;
        }

        # Build Authentication Header
        $this.dictAuth = @{"AUTHORIZATION"="Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($this.User+":"+$this.Password ))}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")

         $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/"+$strUri
        Write-Debug "Using $strUri"
         try {
            
            
            $response = Invoke-WebRequest -Uri $strUri -Headers $this.dictAuth -Method PUT -UseBasicParsing -Body $dictPayload  -ContentType "application/x-www-form-urlencoded" -ea stop
            $retObj = ConvertFrom-Json -InputObject $response.Content

            return $retObj

        } catch [System.Net.WebException] { 
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

        if ( !$this.waitForFreeSlot(10) ){
            Write-Error "System is not ready. Aborting"  -ErrorAction Stop
            return $null;
        }

        # Build Authentication Header
        $this.dictAuth = @{"AUTHORIZATION"="Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($this.User+":"+$this.Password ))}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")

        $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/"+$strUri
        Write-Debug "Using $strUri"
        try {
            
            
            $response = Invoke-WebRequest -Uri $strUri -Headers $this.dictAuth -Method DELETE -UseBasicParsing -ContentType "application/x-www-form-urlencoded" 
            $retObj = ConvertFrom-Json -InputObject $response.Content

            return $retObj

        } catch [System.Net.WebException] { 
            ExceptionOutput $_.Exception
            return $null
        } 
    }

    # Check given host Version against minimum Version needed.
    # Param hostVersionNeeded
    # Returns true if Version is minimum version, false if version is below min version

    [Boolean] minVersion ( [String] $hostVersionNeeded ){


        if ( ! $this.osversion ){
            $this.setSystemVersion()
        }


        $intOsversion = $this.osversion -replace "\.", ""
        $intHostVersion  = $hostVersionNeeded -replace "\.", ""

        write-debug "Comparing $intOsversion"
        if ( $intOsversion -lt $intHostVersion ){
            write-error "Version not supported. Please update your Silent Brick System first to a minimum version of $hostVersionNeeded." -ErrorAction Stop
            exit
        }

        return $true


    }

    # Wait for free Task Slot
    # Returns: true or false if no slot was found in time
    [boolean] waitForFreeSlot ( [int] $retries ){

        if ( ! $this.osversion ){
            $this.setSystemVersion()
        }


        $intOsversion = $this.osversion -replace "\.", ""

        write-debug "Comparing $intOsversion"
        if ( $intOsversion -lt 215 -Or ! $this.checkTasksFirst){
            write-debug "Old Version or Task check disabled."
            return $true
        }

        for ($i=1; $i -le $retries; $i++){
            
            Write-Debug("Waiting for free slot - Cycle $i")
            # Check if system is busy
            $ret = $this.getTasksRunning( )
            if( ! $ret ){
                return $true
            }
            sleep 1
        }
        return $false
            
        
    }

    # Check if current tasks are running
    # Returns: 1 or 0
    [boolean] getTasksRunning () 
    {
            $this.minVersion( "2.15" );

            # Build Authentication Header
            $this.dictAuth = @{"AUTHORIZATION"="Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($this.User+":"+$this.Password ))}
            $this.dictAuth.Add("cache-control", "no-cache")
            $this.dictAuth.Add("Content-Type","application/json")

            $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/tasks_active.json"

             try {
                
                $response = Invoke-WebRequest -Uri $strUri -Headers $this.dictAuth -Method GET -UseBasicParsing
            
                $retObj = ConvertFrom-Json -InputObject $response.Content

                if(! $retObj.tasks_active ){
                    return $false
                }else{
                    return $true
                }

            } catch [System.Net.WebException] { 
                ExceptionOutput $_.Exception
                return $null
            } 


  
            

    }

   <# -------------------- GENERAL BRICK METHODS -------------------- #> 
   # get and output all available free bricks
   # Returns: Object with result or empty Object
    [Object] getFreeBricks () 
    {

        $this.minVersion( "2.15" );


        $strEndpoint = "bricks"

        $URL = "$strEndpoint"+".json"
        
        $response = $this.executeGetRequest( $URL )
        return $response.bricks

    }

   # get and output all known bricks
   # Returns: Object with result or empty Object
    [Object] getBricks () 
    {

        $this.minVersion( "2.15" );

        $strEndpoint = "bricks"

        $URL = "$strEndpoint"+".json?all"
        
        $response = $this.executeGetRequest( $URL )
        return $response.bricks

    }


    # Update the Brick Description
    # Param String Brick Serial Number
    # Param String description
    #       Int displaymode 
    #           0 = QR - Description + ContainerID
    #           1 = QR - Description only
    #           2 = Text Display - Top & Left Aligned
    #           3 = Text Display - Top & Center
    #           4 = Text Display - Top & Right Aligned
    #           5 = Text Display - Middle & Center
    #       String Description
    # Returns 1 for succes, 0 for false
    [int] updateBrickDescription ( [String]$strBrickSerial, [String]$strDescription, [Int]$intDisplaymode )
    {

        $this.minVersion( "2.15" );

        $intRet = 1

        $strBrickID   = $this.getBrickIDBySerial( $strBrickSerial )
        

        if( ! $strBrickID ){
            write-debug "No Brick ID found $strBrickSerial"
            return 0
        }



        $strEndpoint    = "bricks"
        $strTask        = "snapshot"

        $strURL         = "$strEndpoint/$strBrickID"+".json"

        # Create Payload for a PUT Request
        $dictPayload = @{}
        $dictPayload.Add('description', $strDescription)
        $dictPayload.Add('display_mode', $intDisplaymode)

        if( $this.executePutRequest( $strURL, $dictPayload ) ){
            return 1
        }
        return 0
    }


    # Translate a Brick Serial to a Brick ID
    # Param: BrickSerial
    # Returns: string with brick uuid or null
    [String] getBrickIDBySerial ([String]$strBrickName)
    {

        $this.minVersion( "2.15" );


        $strEndpoint = "bricks"

        $strURL = "$strEndpoint"+".json"
        
        $response = $this.executeGetRequest( $strURL )

        $strBrickIDRet = $null

        # fetch the bricks infos now
        if( $response ){
            $response.bricks | foreach-object { 
                $objBrick = $_
                    if (! [string]::IsNullOrEmpty($objBrick.serial) -And $objBrick.serial  -eq $strBrickName ) {
                       $strBrickIDRet = $objBrick.uuid
                    }
            }
        }
        return $strBrickIDRet

    }




   <# -------------------- VOLUME METHODS -------------------- #> 

   # get and output partitions info of a given volume
   # Returns: Object with result or empty Object
    [Object] getVolumes () 
    {
        $this.minVersion( "2.10" );


        $strEndpoint = "volumes"

        $URL = "$strEndpoint"+".json"
        
        $response = $this.executeGetRequest( $URL )
        return $response.volumes

    }

    # Translate a Volume Name to a Volume ID
    # get and output partitions info of a given volume
    # Param: VolumeName
    # Returns: string with volume uuid or null
    [String] getVolumeIDByName ([String]$strVolumeName)
    {
        $this.minVersion( "2.10" );



        $strEndpoint = "volumes"

        $strURL = "$strEndpoint"+".json"
        
        $response = $this.executeGetRequest( $strURL )

        $strVolumeIDReturn = $null

        # fetch the volumes partitions infos now
        if( $response ){
            $response.volumes | foreach-object { 
                $objVolume = $_
                    if (! [string]::IsNullOrEmpty($objVolume.name) -And $objVolume.name  -eq $strVolumeName ) {
                       $strVolumeIDReturn = $objVolume.uuid
                    }
            }
        }
        return $strVolumeIDReturn

    }

    # get and output partitions info of a given volume
    # Param: VolumeID
    # Returns: Object with result or null
    [Object] getPartitionsByVolumeID ([String]$strVolumeID) 
    {
        $this.minVersion( "2.10" );

        $strEndpoint = "volumes"
        $strTask = "partitions"

        $URL = "$strEndpoint/$strVolumeID/$strTask"+".json"
        
        $response = $this.executeGetRequest( $URL )
        return $response.partitions

    }


    # switch online / offline per volume
    # Param String Volume ID
    #       String State may be 'online' or 'offline'
    # Returns true on success
    [Object] setVolumeState ([String]$strVolumeID, [string]$strVolumeState ) 
    {

        #TBT
        $this.minVersion( "2.15" );

        $strTask = 'set_online'

        if( $intVolumeState -eq "offline" ){
            $strTask = 'set_offline'
        }

        $strEndpoint    = "volumes"

        $URL            = "$strEndpoint/$strVolumeID/$strTask"+".json"
        
        $response = $this.executePutRequest( $URL )
        
        return $response

    }

    # Unlock a brick
    # Param: VolumeID
    # Returns: true or false
    [boolean] setVolumeUnlock ([String]$strVolumeID) 
    {
        #TBT
        $this.minVersion( "2.15" );

        $objPartitions = $this.getPartitionsByVolumeID( $strVolumeID )

        if( !$objPartitions.uuid ){
            return $false;
        }


        $strEndpoint = "volumes"
        $strPartition = $objPartitions.uuid
        $strTask      =      "partitions"

        $URL = "volumes/$strVolumeID/partitions/$strPartition/unlock.json"
        
        $response = $this.executePutRequest( $URL )
        return $response

    }



    <# -------------------- MONITORING METHODS -------------------- #> 
    # get and output open issues
    # Type may be all, error, info, warning
    # Param: type may be all (default), error, info, warning.
    # Returns: Object with result or empty Object
    [Object] getOpenIssues ([String]$strTypeSearch) 
    {
        $this.minVersion( "2.10" );



        $strEndpoint    = "open_issues"
        $strURL         = $strEndpoint+".json"
        $issues         = $null
        $response       = $this.executeGetRequest( $strURL )


        if( $strTypeSearch -ne "all" -And $response)
        {
            $issues = @()
            # fetch the volumes partitions infos now
            $response | foreach-object { 

                $type = $_."Error Level"

                write-debug "Comparing $type against $strTypeSearch"
                if( $type -eq $strTypeSearch){
                     $issues = $issues += $_
                     # Add to empty array 
                 }
            }
        }else{
            $issues = $response
        }

        return $issues
    }

    # get and output partitions info of a given volume
    # Type may be all, error, info, warning
    # get and output partitions info of a given volume
    # Param: type may be all (default), error, info, warning.
    # Returns: Object with result or empty Object
    [Object] getSystemInfo () 
    {
        $this.minVersion( "2.10" );


        $strEndpoint    = "hardware_info"
        $strURL         = $strEndpoint+".json"      
        $response       = $this.executeGetRequest( $strURL )

        return $response.system
    }

    [boolean] setSystemVersion ()
    {

        # Set a default first. This is needed because the default will be checked later
        # If the default is 2.15, he will always try to poll the tasks state first with the get call
        # But the Task state is not implemented in versions prior 2.15
        $this.osversion = "2.10"
        
        $systemInfo = $this.getSystemInfo()

        if( $systemInfo -And $systemInfo.hardware.site.devices.device ){

            $systemInfo.hardware.site.devices.device | foreach-object {

                if( $_.version -match "([0-9]\.[0-9]+)\." ){
                    $this.osversion = $matches[1]
                    write-debug "Updated OS Version to $($this.osversion)"
                    return $true
                }
                return $false
            }
        }
        return $false
    }

    <# -------------------- SNAPSHOT METHODS -------------------- #> 

    # Create a snapshot with the given name
    # Param String Volume ID
    #       String Snapshot Name
    #       String Description
    # Returns 1 for succes, 0 for false
    [int] createSnapshot ( [String]$strVolumeID, [String]$strSnapshotName, [String]$strDescription )
    {

        $this.minVersion( "2.15" );

        $intRet = 1



        $strEndpoint    = "volumes"
        $strTask        = "snapshot"

        $strURL         = $strEndpoint+".json"
        $strURL         = "$strEndpoint/$strVolumeID/$strTask"+".json"

        # Create Payload for a PUT Request
        $dictPayload = @{}
        $dictPayload.Add('name', $strSnapshotName)
        $dictPayload.Add('description', $strDescription)

        if( $this.executePutRequest( $strURL, $dictPayload ) ){
            return 1
        }
        return 0
    }


     # get and output partitions info of a given volume
     # Param String Volume ID
     # Returns object or null
    [Object] getSnapshotsByVolumeID ([String]$strVolumeID) 
    {
        $this.minVersion( "2.15" );


        $strEndpoint    = "volumes"
        $strTask        = "list_snapshots"

        $URL            = "$strEndpoint/$strVolumeID/$strTask"+".json"
        
        $response = $this.executeGetRequest( $URL )
        if( $response.snapshots ){
            return $response.snapshots
        }
        return $null

    }

    # get and output partitions info of a given volume
    # Param String Snapshot ID
    # Returns 1 or 0
    [int] deleteSnapshotByID ([String]$strSnapshotID) 
    {

        $this.minVersion( "2.15" );

        $strEndpoint    = "snapshots"
        $URL            = "$strEndpoint/$strSnapshotID"+".json"
        
    
        if( $this.executeDeleteRequest( $URL ) ){
            return 1
        }
        
        return 0        

    }

    <# -------------------- REPLICATION METHODS -------------------- #> 

    # get all replication target of a volume by id
    # Param String Volume ID
    # Returns object or null
    [Object] getReplicationsByVolumeID ([String]$strVolumeID) 
    {

        #TBT
        $this.minVersion( "2.15" );


        $strEndpoint    = "volumes"
        $strTask        = "list_replications"

        $URL            = "$strEndpoint/$strVolumeID/$strTask"+".json"
        
        $response = $this.executeGetRequest( $URL )
        if( $response.replications ){
            return $response.replications
        }
        return $null

    }



}







