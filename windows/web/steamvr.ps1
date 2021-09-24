[CmdletBinding(PositionalBinding=$false)]
param (
    [parameter(Position=0)][string]$SteamPath,
    [parameter(Position=1)][string]$DriverPath,
    [parameter(Position=2)][switch]$Uninstall = $false
)

# Prune external SlimeVR driver(s) and possibly invalid entries
$OpenVrConfig = Get-Content -Path "$env:LOCALAPPDATA\openvr\openvrpaths.vrpath" | ConvertFrom-Json
$DriverPaths = @()
if ($OpenVrConfig.external_drivers.Length) {
    foreach ($DriverPath in $OpenVrConfig.external_drivers) {
        if (-not (Test-Path -Path "$DriverPath\driver.vrdrivermanifest")) {
            continue
        }
        $DriverManifest = Get-Content -Path "$DriverPath\driver.vrdrivermanifest" | ConvertFrom-Json
        if ($DriverManifest.name -eq "SlimeVR") {
            continue
        }
        $DriverPaths += $DriverPath
    }
}
if ($DriverPaths.Length -eq 0) {
    $OpenVrConfig.external_drivers = $null
} else {
    $OpenVrConfig.external_drivers = $DriverPaths
}
ConvertTo-Json -InputObject $OpenVrConfig | Out-File -FilePath "$env:LOCALAPPDATA\openvr\openvrpaths.vrpath"

$DriverFolder = Split-Path -Path $DriverPath -Leaf
$SteamVrPath = "$SteamPath\steamapps\common\SteamVR"
if ((Test-Path -Path "$SteamVrPath\bin") -eq $true) {
    if ($Uninstall -eq $true) {
        Remove-Item -Recurse -Path "$SteamVrPath\drivers\$DriverFolder"
        return
    }
    Copy-Item -Recurse -Force -Path $DriverPath -Destination "$SteamVrPath\drivers"
    return
}

$res = Select-String -Path "$SteamPath\steamapps\libraryfolders.vdf" -Pattern '"path"\s+"(.+?)"' -AllMatches
foreach ($Match in $res.Matches) {
    $LibraryPath = $Match.Groups[1] -replace "\\\\", "\"
    $SteamVrPath = "$LibraryPath\steamapps\common\SteamVR"
    if ((Test-Path -Path "$SteamVrPath\bin") -eq $true) {
        if ($Uninstall -eq $true) {
            Remove-Item -Recurse -Path "$SteamVrPath\drivers\$DriverFolder"
            return
        }
        Copy-Item -Recurse -Force -Path $DriverPath -Destination "$SteamVrPath\drivers"
        return
    }
}

exit 1