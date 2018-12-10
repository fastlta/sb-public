# Windows Powershell Scripts
Sample Code to demonstrate usage of the _FAST LTA Silent Bricks Public REST API_ in combination with the Silent Brick System

### Purpose

The sample scripts can be used as is without any warranty.
They are ment to show how to use the __FAST LTA Silent Bricks Public REST API__ to demonstrate how to fetch different values, create volumes and shares and alike.   
You may find sample scripts for ordered by the different OS types you may use them for.

### Installation

Install at least the main class file "FAST.ps1" into any folder on your Windows host.
The class file may be included in other Powershell scripts in order to call defined functions.

#### Example 

# Initialize Object
$mycontroller = New-Object SilentBrick
$mycontroller.IP = $Hostname
$mycontroller.User = $Username
$mycontroller.Password = $Password

$allBricks = $mycontroller.getBricks()


#### License

All code is provided under Apache License, Version 2.0.  
Please read at:
    * http://www.apache.org/licenses/LICENSE-2.0
