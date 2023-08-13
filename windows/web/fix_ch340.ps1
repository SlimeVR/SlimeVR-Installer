function FindCH340 {
    # Find CH340 OEM driver name

    $driverList = pnputil /enum-drivers
    $driverList = $driverList -split "`r`n"
    
    $previousLine = $null
    foreach ($line in $driverList) {
        if ($line -like "*ch341ser.inf*") {
            if ($previousLine) {
                $previousLine = $previousLine -replace 'Published Name:     ', ''
                return $previousLine
            } else {
                return $null
            }
        }
        $previousLine = $line
    } 
}

function WaitForCH340 {
    $HardwareID = "USB\VID_1A86&PID_7523"
    $DelaySeconds = 1

    do {
        $device = Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPDeviceID -like "*$HardwareID*" }
        if ($device) {
            return $true
        }
        Write-Host -NoNewLine "`rWaiting for CH340..."
        Start-Sleep -Seconds $DelaySeconds
    } while ($true)
}

function CleanUp {
    Remove-Item $env:temp\CH341 -Recurse -Force | Out-Null
}

# Self-elevate the script
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
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

if (WaitForCH340) {
    Write-Host "CH340 found!"
    Write-Host ""
    Write-Host "Removing broken CH340 driver..."

    $driver = FindCH340
    if ($null -eq $driver) {
        Write-Host ""
        Write-Host "No CH340 driver found."
        Write-Host ""
    } else {
        pnputil /delete-driver $driver /uninstall | Out-Null 
        Write-Host "OK."
        Write-Host ""
    }

    # Downloads 2014 driver
    # Probably not the safest to be hosting on my own CDN, can change
    Write-Host "Downloading working CH340 driver..."
    New-Item -ItemType Directory -Path $env:temp\CH341 -ErrorAction SilentlyContinue | Out-Null
    Invoke-WebRequest -Uri 'cdn.kouno.xyz/YZSvN1b5.zip' -OutFile $env:temp\CH341\CH341SER.ZIP | Out-Null
    Write-Host "OK."
    Write-Host ""

    Write-Host "Extracting working CH340 driver..."
    Expand-Archive -Path $env:temp\CH341\CH341SER.ZIP -DestinationPath $env:temp\CH341\ -Force
    Write-Host "OK."
    Write-Host ""

    Write-Host "Installing working CH340 driver..."
    pnputil /add-driver $env:temp\CH341\CH341SER.INF /install | Out-Null
    Write-Host "OK."
    Write-Host ""

    Write-Host "Adding registry values to prevent driver updates..."
    
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
    New-Item -Path $registryPath -Force | Out-Null

    $denyDeviceIDsPath = "$registryPath\DenyDeviceIDs"
    New-Item -Path $denyDeviceIDsPath -Force | Out-Null

    Set-ItemProperty -Path $registryPath -Name "DenyDeviceIDs" -Value 1
    Set-ItemProperty -Path $registryPath -Name "DenyDeviceIDsRetroactive" -Value 0
    Set-ItemProperty -Path $denyDeviceIDsPath -Name "1" -Value "USB\VID_1A86&PID_7523"
    Set-ItemProperty -Path $denyDeviceIDsPath -Name "2" -Value "USB\VID_1A86&PID_7523&REV_0254"

    Write-Host "OK."
    Write-Host ""

    Write-Host "Cleaning up..."
    CleanUp
    Write-Host "OK."
    Write-Host ""
}

Write-Host "Success! Your CH340 should work now."
Write-Host "Press any key to exit."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
