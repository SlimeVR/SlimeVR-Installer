[CmdletBinding(PositionalBinding=$true)]
param (
    [parameter(Position=0)][string]$SteamPath,
    [parameter(Position=1)][string]$DriverPath,
    [parameter(Position=2)][string]$Action,
    [parameter(Position=3)][string]$SystemType
)

function Call-VrPathReg([string]$Path) {
    Start-Process -FilePath $Path -ArgumentList "$Action", "`"$DriverPath`"" -Wait
}

if ((Test-Path -Path "$SteamPath\steamapps\common\SteamVR\bin\$SystemType\vrpathreg.exe") -eq $true) {
    Call-VrPathReg -Path "$SteamPath\steamapps\common\SteamVR\bin\$SystemType\vrpathreg.exe"
    return 0
}

$res = Select-String -Path "$SteamPath\steamapps\libraryfolders.vdf" -Pattern '"path"\s+"(.+?)"' -AllMatches
foreach ($Match in $res.Matches) {
    $LibraryPath = $Match.Groups[1] -replace "\\\\", "\"
    $SteamVrBinPath = "$LibraryPath\steamapps\common\SteamVR\bin"
    if ((Test-Path -Path $SteamVrBinPath) -eq $true) {
        Call-VrPathReg -Path "$SteamVrBinPath\$SystemType\vrpathreg.exe"
        return 0
    }
}