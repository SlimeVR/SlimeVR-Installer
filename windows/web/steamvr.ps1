[CmdletBinding(PositionalBinding=$false)]
param (
    [parameter(Position=0)][string]$SteamPath,
    [parameter(Position=1)][string]$DriverPath,
    [parameter(Position=2)][switch]$Uninstall = $false
)

# Prune external SlimeVR driver(s)
$OpenVrConfigPath = "$env:LOCALAPPDATA\openvr\openvrpaths.vrpath"
$OpenVrConfig = Get-Content -Path $OpenVrConfigPath -Encoding utf8 | ConvertFrom-Json
Write-Host "Checking `"$OpenVrConfigPath`" for SlimeVR Drivers..."
$ExternalDriverPaths = @()
if ($OpenVrConfig.external_drivers -and $OpenVrConfig.external_drivers.Length) {
    foreach ($ExternalDriverPath in $OpenVrConfig.external_drivers) {
        if (-not (Test-Path -Path "$ExternalDriverPath\driver.vrdrivermanifest")) {
            Write-Host "VR driver path `"$ExternalDriverPath`" has no manifest."
            $ExternalDriverPaths += $ExternalDriverPath
            continue
        }
        $DriverManifest = Get-Content -Path "$ExternalDriverPath\driver.vrdrivermanifest" -Encoding utf8 | ConvertFrom-Json
        if ($DriverManifest.name -eq "SlimeVR") {
            Write-Host "Found external SlimeVR Driver in `"$ExternalDriverPath`". Removing..."
            continue
        }
        $ExternalDriverPaths += $ExternalDriverPath
    }
}
if ($ExternalDriverPaths.Length -eq 0) {
    $OpenVrConfig.external_drivers = $null
} else {
    $OpenVrConfig.external_drivers = $ExternalDriverPaths
}
[System.IO.File]::WriteAllLines($OpenVrConfigPath, (ConvertTo-Json -InputObject $OpenVrConfig))

# Remove trackers on uninstall
if ($Uninstall -eq $true) {
    $SteamVrSettingsPath = "$SteamPath\config\steamvr.vrsettings"
    Write-Host "Removing trackers from `"$SteamVrSettingsPath`""
    $SteamVrSettings = (Get-Content -Path $SteamVrSettingsPath -Encoding utf8) -creplace "/devices/SlimeVR/", "/devices/SlimeVR1/" | ConvertFrom-Json
    if ($SteamVrSettings.trackers) {
        $SettingsTrackers = $SteamVrSettings.trackers.PSObject.Properties
        $Trackers = New-Object -TypeName PSCustomObject
        if ($SettingsTrackers.Value.Count) {
            foreach ($Tracker in $SettingsTrackers) {
                if ($Tracker.Name -match "^/devices/slimevr(1)?/") {
                    continue
                }
                Add-Member -InputObject $Trackers -MemberType NoteProperty -Name $Tracker.Name -Value $Tracker.Value
            }
        }
        $SteamVrSettings.trackers = $Trackers
        [System.IO.File]::WriteAllLines($SteamVrSettingsPath, (ConvertTo-Json -InputObject $SteamVrSettings))
    }
}

$SteamVrPaths = @("$SteamPath\steamapps\common\SteamVR")
$res = Select-String -Path "$SteamPath\steamapps\libraryfolders.vdf" -Pattern '"path"\s+"(.+?)"' -AllMatches
foreach ($Match in $res.Matches) {
    $LibraryPath = $Match.Groups[1] -replace "\\\\", "\"
    $SteamVrPaths += "$LibraryPath\steamapps\common\SteamVR"
}

Write-Host "Attempting to find SteamVR..."
$DriverFolder = Split-Path -Path $DriverPath -Leaf
foreach ($SteamVrPath in $SteamVrPaths) {
    if (Test-Path -Path "$SteamVrPath\bin") {
        $SteamVrDriverPath = "$SteamVrPath\drivers\$DriverFolder"
        if (Test-Path -Path $SteamVrDriverPath) {
            Remove-Item -Recurse -Path $SteamVrDriverPath
        }
        if ($Uninstall -eq $true) {
            Write-Host "Deleted SlimeVR Driver from `"$SteamVrDriverPath`""
            exit 0
        }
        Copy-Item -Recurse -Force -Path $DriverPath -Destination "$SteamVrPath\drivers"
        Write-Host "Installed SlimeVR Driver to `"$SteamVrDriverPath`""
        exit 0
    }
}

Write-Host "No SteamVR folder was found."
exit 1