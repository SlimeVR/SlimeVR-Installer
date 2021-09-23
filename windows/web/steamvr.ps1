[CmdletBinding(PositionalBinding=$false)]
param (
    [parameter(Position=0)][string]$SteamPath,
    [parameter(Position=1)][string]$DriverPath,
    [parameter(Position=2)][switch]$Uninstall = $false
)

$DriverFolder = Split-Path -Path $DriverPath -Leaf
$SteamVrPath = "$SteamPath\steamapps\common\SteamVR"
if ((Test-Path -Path "$SteamVrPath\bin") -eq $true) {
    if ($Uninstall -eq $true) {
        Remove-Item -Recurse -Path "$SteamVrPath\drivers\$DriverFolder"
        return 0
    }
    Copy-Item -Recurse -Force -Path $DriverPath -Destination "$SteamVrPath\drivers"
    return 0
}

$res = Select-String -Path "$SteamPath\steamapps\libraryfolders.vdf" -Pattern '"path"\s+"(.+?)"' -AllMatches
foreach ($Match in $res.Matches) {
    $LibraryPath = $Match.Groups[1] -replace "\\\\", "\"
    $SteamVrPath = "$LibraryPath\steamapps\common\SteamVR"
    if ((Test-Path -Path "$SteamVrPath\bin") -eq $true) {
        if ($Uninstall -eq $true) {
            Remove-Item -Recurse -Path "$SteamVrPath\drivers\$DriverFolder"
            return 0
        }
        Copy-Item -Recurse -Force -Path $DriverPath -Destination "$SteamVrPath\drivers"
        return 0
    }
}