# 
# Author: Rene Weber, FAST LTA AG, 2018
#
# Script: SB System XML Creator
#
# Purpose: 
# Provides a User Interface to create an XML Configuration file for the Silent Brick Connection
# 
# Needs latest FAST.ps1
# Start this Script in order to create a new XML Config File
# 
# License: This script is under Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)



$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

try {
    . ("$ScriptDirectory\FAST.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
    exit 0
}



function AskForInput 
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



function AskForSelection
{

    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $heading,
         [Parameter(Mandatory=$true, Position=1)]
         [array] $options,
         [Parameter(Mandatory=$false, Position=3)]
         [int] $choices
             
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Please help me help you'
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
    $label.Text = $heading
    $form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.Listbox
    $listBox.Location = New-Object System.Drawing.Point(10,40)
    $listBox.Size = New-Object System.Drawing.Size(260,20)


    $listBox.SelectionMode = 'MultiSimple'

    if( $choices -eq 1 ){

        $listBox.SelectionMode = 'One'

    }

    $options | foreach-object {

        [void] $listBox.Items.Add($_)

    }



    $listBox.Height = 70
    $form.Controls.Add($listBox)
    $form.Topmost = $true


    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $x = $listBox.SelectedItems
        return $x
    }


}



$mycontroller = New-Object SilentBrick
$SilentBrickConfig = $mycontroller.StartInteractiveConfig()



$VeeamModi = @( "WLC - Write Lock Cleanup", "WCT - Write Clone Transport")
$veeamMode = AskForSelection "Please choose your required Veeam Mode" $VeeamModi 1

Switch ($veeamMode)
{
       "WLC - Write Lock Cleanup" {

            # Get List of Free Bricks
            $VolumeNames = @()

            $Volumes = $mycontroller.getVolumes()

            $Volumes | foreach-object {
                    $VolumeNames += ( $_.name )
            }

            $volumename = AskForSelection "Please select the target Volume:" $VolumeNames 1

            $minutes    = AskForInput("For how many Minutes do you want to keep the Snapshots?")

            $code   = "`"$PSScriptRoot\VEEAM-WLC_Secure.ps1`" -Hostname " + $mycontroller.IP + " -Username " + $mycontroller.User + " -Password " + $mycontroller.Password + " -Volume $volumename -Minutes $minutes " 
            Set-Clipboard( $code )

            $string = "The following command is now in your Clipboard.`nIt should be added to the Postscript option for your Veeam Backup Job:`n`n$code"
            [System.Windows.Forms.MessageBox]::Show($string,"Use this code as Postscript",0)
            
            exit


        }
       "WCT - Write Clone Transport" {


            # Get List of Free Bricks
            $VolumeNames = @()

            $Volumes = $mycontroller.getVolumes()

            $Volumes | foreach-object {
                    $VolumeNames += ( $_.name )
            }

            $volumename = AskForSelection "Please select the target Volume:" $VolumeNames 1

            # Get List of Free Bricks
            $targetBricksUsed = @()
            $FreeSerials = @()


            $FreeBricks = $mycontroller.getFreeBricks()

            $FreeBricks | foreach-object {
                    $FreeSerials += ( $_.serial )
            }


           $bricks = AskForSelection "Please choose the free Bricks that may be used as clone targets:" $FreeSerials

           $string = "You will now get 2 codelines:`n- One for the PRE-Script part`n- One for the POST-Script part of your Backup Job."
           [System.Windows.Forms.MessageBox]::Show($string,"Click OK to continue",0)

           $code   = "`"$PSScriptRoot\VEEAM-WCT_Secure.ps1`" -Hostname " + $mycontroller.IP + " -Username " + $mycontroller.User + " -Password " + $mycontroller.Password + " -Volume $volumename -Task pre -Targets " + ( $bricks -join "," )    
           Set-Clipboard( $code )
           $string = "The following command is now in your Clipboard.`nIt should be added to the PRE Script option for your Veeam Backup Job.`nContinue with OK.`n`n$code"
           [System.Windows.Forms.MessageBox]::Show($string,"Use this code as PRE-script",0)

           $code   = "`"$PSScriptRoot\VEEAM-WCT_Secure.ps1`" -Hostname " + $mycontroller.IP + " -Username " + $mycontroller.User + " -Password " + $mycontroller.Password + " -Volume $volumename -Task post"
           Set-Clipboard( $code )
           $string = "The following command is now in your Clipboard.`nIt should be added to the POST Script option for your Veeam Backup Job:`n`n$code"
           [System.Windows.Forms.MessageBox]::Show($string,"Use this code as POST-script",0)
           

            exit


        }
}



Write-Host "Awesome. You chose $choice"


