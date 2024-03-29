<#
.SYNOPSIS
   Class Module for Silent Brick API Calls

.DESCRIPTION
   This Class module may be used for various Powershell Scripts and supports calls for many different API commands.
    
   For Debugging Purpose set 
        $DebugPreference = "Continue"

.NOTES
    Author: René Weber
    Date:   27.04.2021     

    License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)
    
    For Debugging Purpose set 
        $DebugPreference = "Continue"

    Compatibility: Powershell Version >= 5

.EXAMPLE
    ./FAST.ps1

    $mycontroller = New-Object SilentBrick

    $mycontroller.IP = $Hostname
    $mycontroller.User = $Username
    $mycontroller.Password = $Password

    $mycontroller.<method>

#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Tls11,Tls12'

if ($PSVersionTable.PSEdition -eq 'Core') {
    $Script:PSDefaultParameterValues = @{
        "invoke-restmethod:SkipCertificateCheck" = $true
        "invoke-webrequest:SkipCertificateCheck" = $true
    }
} else {
    Add-Type @"
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
}

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


##################################
## Global Drawing function
## Needed for inclution of .Net

function __AskForInput 
{

    param( [String] $title )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Silent Brick Setup'
    $form.Size = New-Object System.Drawing.Size(300,200)
    $form.StartPosition = 'CenterScreen'

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(75,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'OK'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(150,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = $title
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,40)
    $textBox.Size = New-Object System.Drawing.Size(260,20)
    $form.Controls.Add($textBox)

    $form.Topmost = $true

    $form.Add_Shown({$textBox.Select()})
    $result = $form.ShowDialog()

    if ($result -eq ( [System.Windows.Forms.DialogResult]::OK ) )
    {
        $x = $textBox.Text
        return $x
    }
    return ""
}

 # console output function for a given Exception object
function ExceptionOutput ([Exception]$excp)
{
     $msg = $excp.Message
     while ($excp.InnerException) {
         $excp = $excp.InnerException
         $msg += "`n" + $excp.Message
     }
     write-debug( $excp )

     # Warning will continue, Throw will exit.
     #write-warning $msg
     throw $msg
}


Class SilentBrick
{


    [String] $IP        
    [String] $User      
    [String] $Password
    [Object] $SecurePassword
    [Object] $dictAuth
    [String] $osversion
    [int] $checkTasksFirst = 1


     <# -------------------- GENERIC METHODS -------------------- #> 
    # Basic GET API Request
    # Param: Uri, last part after api/v1/
    # Returns: Object with result or empty Object
    [Object] executeGetRequest ([String]$strUri) 
    {

        if ( !$this.waitForFreeSlot(20) ){
            Write-Error "System is not ready. Aborting"  -ErrorAction Stop
            return $null;
        }
 
        if( $this.Password ){
            $this.SecurePassword = ConvertTo-SecureString $this.Password -AsPlainText -Force
        }

        $credential = New-Object System.Management.Automation.PSCredential($this.User, $this.SecurePassword)



        # Build Authentication Header
        $this.dictAuth = @{}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")

        $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/"+$strUri
        Write-Debug "Using $strUri"
         try {
            
            
            $response = Invoke-WebRequest -Uri $strUri -Credential $credential -Headers $this.dictAuth -Method GET -UseBasicParsing
        

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
    [Object] executePutRequest ([String]$strUri, [PSCustomObject] $dictPayload ) 
    {


        if ( !$this.waitForFreeSlot(20) ){
            Write-Error "System is not ready. Aborting"  -ErrorAction Stop
            return $null;
        }

       
        if( $this.Password ){
            $this.SecurePassword = ConvertTo-SecureString $this.Password -AsPlainText -Force
        }

        $credential = New-Object System.Management.Automation.PSCredential($this.User, $this.SecurePassword)



        # Build Authentication Header
        $this.dictAuth = @{}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")


        $jsonbody = $dictPayload | ConvertTo-Json

         $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/"+$strUri
        Write-Debug "Using $strUri"
         try {
            
            
            $response = Invoke-WebRequest -Verbose -Uri $strUri -Credential $credential -Headers $this.dictAuth -Method PUT -UseBasicParsing -Body $jsonbody  -ContentType "application/json" -ea stop
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
    [Object] executePutRequest ([String]$strUri ) 
    {
        return $this.executePutRequest( $strUri, @() )
    }

    # Basic GET API Request
    # Param: Uri, last part after api/v1/
    #        Dictionary for the Payload
    # Returns: Object with result or empty Object
    [Object] executeDeleteRequest ([String]$strUri ) 
    {

        if ( !$this.waitForFreeSlot(20) ){
            Write-Error "System is not ready. Aborting"  -ErrorAction Stop
            return $null;
        }

      
        if( $this.Password ){
            $this.SecurePassword = ConvertTo-SecureString $this.Password -AsPlainText -Force
        }

        $credential = New-Object System.Management.Automation.PSCredential($this.User, $this.SecurePassword)



        # Build Authentication Header
        $this.dictAuth = @{}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")

        $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/"+$strUri
        Write-Debug "Using $strUri"
        try {
            
            
            $response = Invoke-WebRequest -Uri $strUri -Credential $credential -Headers $this.dictAuth -Method DELETE -UseBasicParsing -ContentType "application/x-www-form-urlencoded" 
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

           
        if( $this.Password ){
            $this.SecurePassword = ConvertTo-SecureString $this.Password -AsPlainText -Force
        }

        $credential = New-Object System.Management.Automation.PSCredential($this.User, $this.SecurePassword)



        # Build Authentication Header
        $this.dictAuth = @{}
        $this.dictAuth.Add("cache-control", "no-cache")
        $this.dictAuth.Add("Content-Type","application/json")

            $strUri = "https://" + $this.IP + "/sb-public-api/api/v1/tasks_active.json"

             try {
                
                $response = Invoke-WebRequest -Uri $strUri -Credential $credential -Headers $this.dictAuth -Method GET -UseBasicParsing
            
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

    # get and output all known bricks
   # Returns: Object with result or empty Object
    [Object] getBricksByVolumeName ( [string] $VolumeName ) 
    {

        $this.minVersion( "2.15" );


        if( ! ( $Volume = $this.getVolumeByName( $VolumeName ) ) ) {
            write-error "No Volume found"
            return $false
        }

        if( ! ( $Partitions = $this.getPartitionsByVolumeID( $Volume.uuid ) ) ){
            write-error "No Partitions found"
            return $false
        }

       if( ! ( $Bricks = $this.getBricks() ) ){
            write-error "No Bricks found"
            return $false
       }

       $brickSerialsOfVolume = @()

       $Bricks | foreach-object {
            if( $_.v_devs.uuid -eq $Partitions.uuid ){
                $brickSerialsOfVolume += $_.serial 
            }
        }

        return $brickSerialsOfVolume

    }

    # get and output all known bricks by label/barcode
    # Returns: Object with result or empty Object
    # Thx to Jan W.

    [Object] getBricksByLabel ( [string] $label) 
    {
 
        $this.minVersion( "2.15" );
 
        $strEndpoint = "bricks"
 
        $URL = "$strEndpoint"+".json?all"
        
        $response = $this.executeGetRequest( $URL )
 
        $result = $response.bricks| Where {$_.tapes.label -eq $label}
 
        return $result
 
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

        $strURL = "$strEndpoint"+".json?all"
        
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

    # get and output parition of a given volume name
    # Returns: Object with result or empty Object
    [Object] getVolumeByName( [String] $strVolumeName)
    {

       $this.minVersion( "2.10" );

        $strEndpoint = "volumes"

        $strURL = "$strEndpoint"+".json"
        
        $response = $this.executeGetRequest( $strURL )

        $objReturn = $false;

        # fetch the volumes partitions infos now
        if( $response ){
            $response.volumes | foreach-object { 
                $objVolume = $_
                    if (! [string]::IsNullOrEmpty($objVolume.name) -And $objVolume.name  -eq $strVolumeName ) {
                       $objReturn = $objVolume
                    }
            }
        }
        return $objReturn;

    }

    # get and output parition of a given volume id
    # Returns: Object with result or empty Object
    [Object] getVolumeByID( [String] $strVolumeID)
    {

       $this.minVersion( "2.10" );

        $strEndpoint = "volumes"

        $strURL = "$strEndpoint"+".json"
        
        $response = $this.executeGetRequest( $strURL )

        $objReturn = $false;

        # fetch the volumes partitions infos now
        if( $response ){
            $response.volumes | foreach-object { 
                $objVolume = $_
                    if (! [string]::IsNullOrEmpty($objVolume.uuid) -And $objVolume.uuid  -eq $strVolumeID ) {
                       $objReturn = $objVolume
                    }
            }
        }
        return $objReturn;

    }

    # get and output parition of a given volume id
    # Returns: Object with result or empty Object
    [Object] getVolumeStateByID( [String] $strVolumeID)
    {

       $this.minVersion( "2.10" );

       $stringReturn = $false;

       $volume = $this.getVolumeByID( $strVolumeID );

       if( $volume -And $volume.status ){
            $stringReturn = $volume.status
       }
       return $stringReturn;

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

        if( $strVolumeState -eq "offline" ){
            $strTask = 'set_offline'
        }

        $strEndpoint    = "volumes"

        $URL            = "$strEndpoint/$strVolumeID/$strTask"+".json"
        
        $response = $this.executePutRequest( $URL )
        
        return $response

    }

    # switch online / offline per volume
    # Param String Volume Name
    #       String State may be 'online' or 'offline'
    # Returns true on success
    [Object] setVolumeStateByName ([String]$strVolumeName, [string]$strVolumeState ) 
    {

        #TBT
        $this.minVersion( "2.15" );

        return $this.setVolumeState( $this.getVolumeIDByName( $strVolumeName ), $strVolumeState )
        return $response

    }

    # Unlock bricks of a volume
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


    # Unlock bricks of a volume
    # Param: VolumeName
    # Returns: true or false
    [boolean] setVolumeUnlockByName ([String]$strVolumeName) 
    {
        #TBT
        $this.minVersion( "2.15" );
        return( $this.setVolumeUnlock( $this.getVolumeIDByName( $strVolumeName ) ) )

    }

     # Lock bricks of a volume
    # Param: VolumeID
    # Returns: true or false
    [boolean] setVolumeLock ([String]$strVolumeID) 
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

        $URL = "volumes/$strVolumeID/partitions/$strPartition/lock.json"
        
        $response = $this.executePutRequest( $URL )
        return $response

    }


    # Lock bricks of a volume
    # Param: VolumeName
    # Returns: true or false
    [boolean] setVolumeLockByName ([String]$strVolumeName) 
    {
        #TBT
        $this.minVersion( "2.15" );
        return( $this.setVolumeLock( $this.getVolumeIDByName( $strVolumeName ) ) )

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
                     # Add to empty array 
                     $issues = $issues += $_
                     
                 }
            }
        }else{
            $issues = $response
        }

        return $issues
    }

      # get and output system hardware info 
    # Param: 
    # Return: Object with result or empty object
  
    [Object] getSystemInfo () 
    {
        $this.minVersion( "2.10" );


        $strEndpoint    = "hardware_info"
        $strURL         = $strEndpoint+".json"      
        $response       = $this.executeGetRequest( $strURL )

        return $response
    }

    # get and output system identifier
    # Param: 
    # Return: Object with result or empty object
    [Object] getSystemIdentification () 
    {
        $this.minVersion( "2.10" );


        $strEndpoint    = "identification"
        $strURL         = $strEndpoint+".json"      
        $response       = $this.executeGetRequest( $strURL )

        return $response
    }

    [boolean] setSystemVersion ()
    {

        # Set a default first. This is needed because the default will be checked later
        # If the default is 2.15, he will always try to poll the tasks state first with the get call
        # But the Task state is not implemented in versions prior 2.15
        $this.osversion = "2.10"
        

        # Since Version 2.22 - using system identification. No Admin rights needed   
        $systemID   = $this.getSystemIdentification()
    
        if( $systemID.swversion ){
            if( $systemID.swversion -match "([0-9]\.[0-9]+)\." ){
                    $this.osversion = $matches[1]
                    write-debug "Updated OS Version to $($this.osversion)"
                    return $true
                }         
        }
  
        # Fallback to older versions
         
        $systemInfo = $this.getSystemInfo() 
       
        # Old Firmware had Systemversion under Hardware / Site / Devices
        if( $systemInfo -And $systemInfo.system.hardware.site.devices.device ){

            $systemInfo.system.hardware.site.devices.device | foreach-object {

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


    <# -------------------- SHARE METHODS -------------------- #> 


    # get and output all shares
   # Returns: Object with result or empty Object
    [Object] getShares () 
    {
        $this.minVersion( "2.53" );


        $strEndpoint = "shares"

        $URL = "$strEndpoint"+".json"
        
        $response = $this.executeGetRequest( $URL )
        return $response.shares;

    }

    # get and output share details by share name
    # Returns: Object with result or empty Object
    [Object] getShareByName( [String] $strShareName)
    {

       $this.minVersion( "2.53" );

        $strEndpoint = "shares"

        $strURL = "$strEndpoint"+".json"
        
        $response = $this.executeGetRequest( $strURL )

        $objReturn = $false;

        # fetch the volumes partitions infos now
        if( $response ){
            $response.shares | foreach-object { 
                $objShare = $_
                    if (! [string]::IsNullOrEmpty($objShare.name) -And $objShare.name  -eq $strShareName ) {
                       $objReturn = $objShare
                    }
            }
        }
        return $objReturn;

    }


    # delete share with specific ID
    # Param String SHARE ID
    # Returns 1 or 0
    [int] deleteShareByID ([String]$strShareID) 
    {

        $this.minVersion( "2.15" );

        $strEndpoint    = "shares"
        $URL            = "$strEndpoint/$strShareID"+".json"
        
    
        if( $this.executeDeleteRequest( $URL ) ){
            return 1
        }
        
        return 0        

    }

  
  
    # create share
    # Returns 1 or 0
    [int] addSMBShare ([String]$strVolumeId, [Object]$objShareDetails )
    {

         $this.minVersion( "2.15" );

        $intRet = 1



        $strEndpoint    = "volumes"
        $strTask        = "share"

        $strURL         = $strEndpoint+".json"
        $strURL         = "$strEndpoint/$strVolumeID/$strTask"+".json"



        if( $this.executePutRequest( $strURL, $objShareDetails ) ){
            return 1
        }
        return 0




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


     # get and output Snaphopts a given volume
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


    
     # get the internal ID of a Snapshot by searching for its name and corresponding volumeid
     # Param String Volume ID
     # Returns object or null
    [String] getSnapshotIDByNameAndVolumeID ([String]$strSnapshotname,[String]$strVolumeID) 
    {
        $this.minVersion( "2.15" );


        $strEndpoint    = "snapshots"

        $URL            = "$strEndpoint"+".json"

        $foundID        = $null;
        
        $response = $this.executeGetRequest( $URL )
        if( $response.snapshots ){
            $response.snapshots | foreach-object {
                $uuid          = $_.uuid
                $name          = $_.name 
                $volume      = $_.volume_uuid

                if($name -eq $strSnapshotname -And $volume -eq $strVolumeID ){
                    $foundID = $uuid
                }           
            }
        }
        return $foundID

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

    <# -------------------- REPLICATION / CLONE METHODS -------------------- #> 



    # get all replications 
    # Returns object or null
    [Object] getReplications () 
    {

        $this.minVersion( "2.20" );


        $strEndpoint    = "replications"

        $URL            = "$strEndpoint"+".json"
        
        $response = $this.executeGetRequest( $URL )


        if( $response.replications ){
            return $response.replications
        }
        return $null

    }

    # get all replication target of a volume by id
    # Param String Volume ID
    # Returns object or null
    [Object] getReplicationsByVolumeID ([String]$strVolumeID) 
    {

        
        $this.minVersion( "2.20" );


        $strEndpoint    = "volumes"
        $strTask        = "list_replications"

        $URL            = "$strEndpoint/$strVolumeID/$strTask"+".json"
        
        $response = $this.executeGetRequest( $URL )
        if( $response.replications ){
            return $response.replications
        }
        return $null

    }


    # get Replication ID by target volume name
    # Param String Replication VolumeName
    # Returns String or null
    [String] getReplicationIDByTargetVolumename ([String]$strVolumeName) 
    {

        
        $this.minVersion( "2.20" );

        if( ! ( $allReplications = $this.getReplications() ) ){
            write-error "No Replications found."
            return $null
        }

        $id = $null

        $allReplications | foreach {
            if( $_.target_volume.name -And $_.target_volume.name.toLower() -eq $strVolumeName.toLower() ){
                $id = $_.replication_uuid
            }
        }
        return $id

    }

    # get Replication State by replication volume name
    # Param String Replication VolumeName
    # Returns object or null
    [Object] getReplicationStateByTargetVolumename ([String]$strVolumeName) 
    {

       
        $this.minVersion( "2.20" );


        $strEndpoint    = "replications"
        $strTask        = "state"


        if( ! ( $strReplID = $this.getReplicationIDByTargetVolumename( $strVolumeName ) ) ) {
            write-error "No such replication volume found"
            return $null
        }

        $URL            = "$strEndpoint/$strReplID/$strTask"+".json"
        
        $response = $this.executeGetRequest( $URL )
        
        if( $response ){
            return $response
        }
        return $null

    }

    # Replicate a Brick Volume
    # Param String VolumeName 
    # Param array TargetBrick Pool of Serials
    # Returns 1 for succes, 0 for false
    [int] replicateVolume ( [String]$strVolumeName, [String]$strTargetVolumeName, [String[]]$arrTargetBricksSerials )
    {

        $this.minVersion( "2.15" );

        $intRet = 1

        $arrTargetBricksUUID = @()

        foreach( $serial in $arrTargetBricksSerials ){
            $strBrickID   = $this.getBrickIDBySerial( $serial )
            $arrTargetBricksUUID += $strBrickID    
        }
        
        $strVolumeID = $this.getVolumeIDByName( $strVolumeName )

        if( ! $arrTargetBricksUUID -Or $arrTargetBricksUUID.count -eq 0 -Or !$strVolumeID ){
            write-debug "Brick IDs or Volume not found"
            return 0
        }


      

        $strEndpoint    = "volumes"
        $strTask        = "replication"


        $strURL         = "$strEndpoint/$strVolumeID/$strTask"+".json"

        
        # Create Payload for a PUT Request
        $dictPayload = @{}
        $dictPayload.Add('name', $strTargetVolumeName)
        $dictPayload.Add('description', $strTargetVolumeName)
        $dictPayload.Add('brick_uuids', $arrTargetBricksUUID )
        
        if( $this.executePutRequest( $strURL, $dictPayload ) ){
            return 1
        }
        return 0
    }

    # Convert a Replication to a standard plain volume
    # Param String VolumeName 
    # Returns 1 for succes, 0 for false
    [int] convertReplication ( [String]$strVolumeName )
    {

        $this.minVersion( "2.15" );

        $strReplicationID = $this.getReplicationIDByTargetVolumename( $strVolumeName )

        if( ! $strReplicationID ){
            write-debug " Replication not found"
            return 0
        }


      

        $strEndpoint    = "replications"
        $strTask        = "convert"


        $strURL         = "$strEndpoint/$strReplicationID/$strTask"+".json"

        
        
        if( $this.executePutRequest( $strURL ) ){
            return 1
        }
        return 0
    }




     # Clone a Brick Volume
    # Param String VolumeName 
    # Param array TargetBrick Pool of Serials
    # Returns 1 for succes, 0 for false
    [int] cloneVolume ( [String]$strVolumeName, [String]$strTargetVolumeName, [String[]]$arrTargetBricksSerials )
    {

        $this.minVersion( "2.15" );

        $intRet = 1

        $arrTargetBricksUUID = @()

        foreach( $serial in $arrTargetBricksSerials ){
            $strBrickID   = $this.getBrickIDBySerial( $serial )
            $arrTargetBricksUUID += $strBrickID    
        }
        
        $strVolumeID = $this.getVolumeIDByName( $strVolumeName )

        if( ! $arrTargetBricksUUID -Or $arrTargetBricksUUID.count -eq 0 -Or !$strVolumeID ){
            write-debug "Brick IDs or Volume not found"
            return 0
        }


      

        $strEndpoint    = "volumes"
        $strTask        = "clone_from_now"


        $strURL         = "$strEndpoint/$strVolumeID/$strTask"+".json"

        
        # Create Payload for a PUT Request
        $dictPayload = @{}
        $dictPayload.Add('name', $strTargetVolumeName)
        $dictPayload.Add('description', $strTargetVolumeName)
        $dictPayload.Add('brick_uuids', $arrTargetBricksUUID )
        
        if( $this.executePutRequest( $strURL, $dictPayload ) ){
            return 1
        }
        return 0
    }


    
    <# -------------------- UI and Config File Setup -------------------- #> 


    [boolean] StartXMLConfig( [String] $SilentBrickConfigFile ){


        if (! $SilentBrickConfigFile -Or  -Not (Test-Path $SilentBrickConfigFile) ){ 
            write-host "Config file not found. Please use config file creator first"
            exit
        }


        $SilentBrickConfig = Import-Clixml -Path $SilentBrickConfigFile
        $this.User      = $SilentBrickConfig.User
        $this.SecurePassword  =  $SilentBrickConfig.Password | ConvertTo-SecureString
        $this.IP        = $SilentBrickConfig.IP


        return $true

    }

 
    <# -------------------- UI and Config File Setup -------------------- #> 


    [String] CreateConfigfileInteractively(){


        $SilentBrickConfig = @{}


       <#   # Read IP Adress
        $SilentBrickConfigFilename =  (Read-Host("Please enter the Config Name")) + ".conf"
        if( [string]::IsNullOrEmpty( $SilentBrickConfigFilename ) ){
            exit
        }
        #>

        # Read IP Adress
        $SilentBrickConfig.IP =  Read-Host("Please enter the Silent Brick Controller IP or Hostname")
        if( [string]::IsNullOrEmpty( $SilentBrickConfig.IP ) ){
            exit
        }
        
        $SilentBrickConfigFilename = ($SilentBrickConfig.IP)+".config"

         if ( Test-Path $SilentBrickConfigFilename  ){ 
            write-host "Config file for "+$SilentBrickConfig.IP+" already exists. Not overwriting. Trying to use this."
            return $SilentBrickConfigFilename
        }

        write-host "Please enter your credentials in the popup."
        $credential = Get-Credential -Message 'ok'

        $SilentBrickConfig.User     = $credential.Username
        $SilentBrickConfig.Password =   ConvertFrom-SecureString $credential.Password 
             
        $SilentBrickConfig | Export-Clixml -Depth 5 -Path $SilentBrickConfigFilename

        return $SilentBrickConfigFilename

    }


    [String] CreateConfigfileGUI(){


        $SilentBrickConfig = @{}


          # Read IP Adress
        $SilentBrickConfigFilename =  __AskForInput("Please enter the Config Name:")
        if( [string]::IsNullOrEmpty( $SilentBrickConfigFilename ) ){
            exit
        }
        
         if ( Test-Path $SilentBrickConfigFilename  ){ 
            write-host "Config file already exists. Not overwriting."
            exit
        }

        # Read IP Adress
        $SilentBrickConfig.IP =  __AskForInput("Please enter the Silent Brick Controller IP:")
        if( [string]::IsNullOrEmpty( $SilentBrickConfig.IP ) ){
            exit
        }
        
        $credential = Get-Credential

        $SilentBrickConfig.User     = $credential.Username
        $SilentBrickConfig.Password =   ConvertFrom-SecureString $credential.Password 
             
        $SilentBrickConfig | Export-Clixml -Depth 5 -Path $SilentBrickConfigFilename

        return $SilentBrickConfigFilename

    }


}







