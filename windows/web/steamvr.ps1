[CmdletBinding(PositionalBinding=$false)]
param (
    [parameter(Position=0)][string]$SteamPath,
    [parameter(Position=1)][string]$DriverPath,
    [parameter(Position=2)][switch]$Uninstall = $false
)

# Prune external SlimeVR driver(s) and possibly invalid entries
$OpenVrConfig = Get-Content -Path "$env:LOCALAPPDATA\openvr\openvrpaths.vrpath" | ConvertFrom-Json
$ExternalDriverPaths = @()
if ($OpenVrConfig.external_drivers.Length) {
    foreach ($ExternalDriverPath in $OpenVrConfig.external_drivers) {
        if (-not (Test-Path -Path "$ExternalDriverPath\driver.vrdrivermanifest")) {
            continue
        }
        $DriverManifest = Get-Content -Path "$ExternalDriverPath\driver.vrdrivermanifest" | ConvertFrom-Json
        if ($DriverManifest.name -eq "SlimeVR") {
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

$DriverFolder = Split-Path -Path $DriverPath -Leaf
# Check if SteamVR is located in the Steam installation folder
$SteamVrPath = "$SteamPath\steamapps\common\SteamVR"
if ((Test-Path -Path "$SteamVrPath\bin") -eq $true) {
    if ($Uninstall -eq $true) {
        Remove-Item -Recurse -Path "$SteamVrPath\drivers\$DriverFolder"
        Write-Host "Deleted SlimeVR Driver from `"$SteamVrPath\drivers`""
        exit 0
    }
    Copy-Item -Recurse -Force -Path $DriverPath -Destination "$SteamVrPath\drivers"
    Write-Host "Copied SlimeVR Driver to `"$SteamVrPath\drivers`""
    exit 0
}

# If not, try looking it up in defined library folders
$res = Select-String -Path "$SteamPath\steamapps\libraryfolders.vdf" -Pattern '"path"\s+"(.+?)"' -AllMatches
foreach ($Match in $res.Matches) {
    $LibraryPath = $Match.Groups[1] -replace "\\\\", "\"
    $SteamVrPath = "$LibraryPath\steamapps\common\SteamVR"
    if ((Test-Path -Path "$SteamVrPath\bin") -eq $true) {
        if ($Uninstall -eq $true) {
            Remove-Item -Recurse -Path "$SteamVrPath\drivers\$DriverFolder"
            Write-Host "Deleted SlimeVR Driver from `"$SteamVrPath\drivers`""
            exit 0
        }
        Copy-Item -Recurse -Force -Path $DriverPath -Destination "$SteamVrPath\drivers"
        Write-Host "Copied SlimeVR Driver to `"$SteamVrPath\drivers`""
        exit 0
    }
}

exit 1