# AFAIK this is the only HWID that counterfeit CH340s use
# Well, they have 2 HWIDs according to Windows, but only 1 is needed for detection
$HardwareID = "USB\VID_1A86&PID_7523"

# ! Currently it gets the driver from my own CDN! This might be a security problem.
$DriverZipUrl = 'cdn.kouno.xyz/YZSvN1b5.zip'
$DriverTempPath = Join-Path $env:temp "CH341Fix"
$DriverZipPath = Join-Path $DriverTempPath "CH341SER.ZIP"
$DriverInfPath = Join-Path $DriverTempPath "CH341SER.INF"

# Can be expanded if more fake CH340 HWIDs are found
$DenyDeviceIDs = @(
    "USB\VID_1A86&PID_7523",
    "USB\VID_1A86&PID_7523&REV_0254"
)
function Wait-CH340Device {
    # Wait for CH340 to be connected to register driver
    $DelaySeconds = 1

    do {
        $DeviceFound = Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPDeviceID -like "*$HardwareID*" }
        if ($DeviceFound) {
            return $true
        }
        Write-Host -NoNewLine "`rWaiting for CH340..."
        Start-Sleep -Seconds $DelaySeconds
    } while ($true)
}

function Find-CH340Driver {
    # Find CH340 OEM driver name
    $DriverList = pnputil /enum-drivers
    $DriverList = $DriverList -split "`r`n"
    
    $PreviousLine = $null
    foreach ($Line in $DriverList) {
        if ($Line -like "*ch341ser.inf*") {
            if ($PreviousLine) {
                return ($PreviousLine -replace 'Published Name:     ', '')
            } else {
                return $null
            }
        }
        $PreviousLine = $Line
    } 
}

function Remove-CH340Driver {
    # Remove broken CH340 driver
    $Driver = Find-CH340Driver
    if ($null -eq $Driver) {
        Write-Host "No CH340 driver found!`n"
        Exit-Script
        Exit
    } else {
        pnputil /delete-driver $Driver /uninstall | Out-Null 

    }
}

function Request-CH340Driver {
    # Downloads and extracts the known working driver to a temp directory
    New-Item -ItemType Directory -Path $DriverTempPath -ErrorAction SilentlyContinue | Out-Null
    Invoke-WebRequest -Uri $DriverZipUrl -OutFile $DriverZipPath | Out-Null
    Expand-Archive -Path $DriverZipPath -DestinationPath $DriverTempPath -Force
}

function Install-CH340Driver {
    # Installs newly downloaded driver
    pnputil /add-driver $DriverInfPath /install | Out-Null
}

function Add-RegistryValues {
    # Blocks any further device driver updates to the specified HWIDs
    $RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
    New-Item -Path $RegistryPath -Force | Out-Null

    $DenyDeviceIDsPath = Join-Path $RegistryPath "DenyDeviceIDs"
    New-Item -Path $DenyDeviceIDsPath -Force | Out-Null
    
    Set-ItemProperty -Path $RegistryPath -Name "DenyDeviceIDs" -Value 1
    Set-ItemProperty -Path $RegistryPath -Name "DenyDeviceIDsRetroactive" -Value 0

    $DenyDeviceIDs | ForEach-Object {
        $index = [array]::IndexOf($DenyDeviceIDs, $_) + 1
        Set-ItemProperty -Path $DenyDeviceIDsPath -Name $index -Value $_
    }
}
function Remove-TempFiles {
    Remove-Item $DriverTempPath -Recurse -Force | Out-Null
}

function Exit-Script {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Exit
}

# * Main entry point

# Elevate script if not already running as administrator
# Doesn't seem to work as a function?
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
    Exit
}

Clear-Host
Write-Host @"
------------------------------------------------------------------------------------------------------------------------
---------------------------------------------Counterfeit CH340 driver fixer---------------------------------------------
------------------------------------------------------------------------------------------------------------------------

        This script will attempt to fix driver issues that appear when using a counterfeit / fake CH340 UART chip.

                                    Plug in your CH340 and press any key to continue.

                                

"@

$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
Clear-Host

if (Wait-CH340Device) {
    Write-Host "CH340 found!`n"

    Write-Host "Removing broken CH340 driver...`n"
    Remove-CH340Driver
    Write-Host "OK.`n"

    Write-Host "Downloading and extracting working CH340 driver...`n"
    Request-CH340Driver
    Write-Host "OK.`n"

    Write-Host "Installing working CH340 driver...`n"
    Install-CH340Driver
    Write-Host "OK.`n"

    Write-Host "Adding registry values to prevent driver updates...`n"
    Add-RegistryValues
    Write-Host "OK.`n"

    Write-Host "Cleaning up...`n"
    Remove-TempFiles
    Write-Host "OK.`n"

    Write-Host "Successfully fixed CH340 driver. Your CH340 should work now!`n"
    Exit-Script
}