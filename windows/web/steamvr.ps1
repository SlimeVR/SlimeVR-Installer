[CmdletBinding(PositionalBinding=$false)]
param (
    [parameter(Position=0)][string]$SteamPath,
    [parameter(Position=1)][string]$DriverPath,
    [parameter(Position=2)][switch]$Uninstall = $false
)

# Prune external SlimeVR driver(s)
$OpenVrConfigPath = "$env:LOCALAPPDATA\openvr\openvrpaths.vrpath"
$OpenVrConfig = Get-Content -Path $OpenVrConfigPath | ConvertFrom-Json
Write-Host "Checking `"$OpenVrConfigPath`" for SlimeVR Drivers..."
$ExternalDriverPaths = @()
if ($OpenVrConfig.external_drivers.Length) {
    foreach ($ExternalDriverPath in $OpenVrConfig.external_drivers) {
        if (-not (Test-Path -Path "$ExternalDriverPath\driver.vrdrivermanifest")) {
            Write-Host "VR driver path `"$ExternalDriverPath`" has no manifest. Skipping..."
            $ExternalDriverPaths += $ExternalDriverPath
            continue
        }
        $DriverManifest = Get-Content -Path "$ExternalDriverPath\driver.vrdrivermanifest" | ConvertFrom-Json
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
ConvertTo-Json -InputObject $OpenVrConfig | Out-File -FilePath "$env:LOCALAPPDATA\openvr\openvrpaths.vrpath"

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