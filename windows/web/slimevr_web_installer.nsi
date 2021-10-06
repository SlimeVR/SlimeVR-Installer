Unicode True

!include x64.nsh 		; For RunningX64 check
!include LogicLib.nsh	; For conditional operators
!include nsDialogs.nsh  ; For custom pages

# Define name of installer
Name SlimeVR Installer

SpaceTexts none # Don't show required disk space since we don't know for sure
SetOverwrite on
SetCompressor lzma  # Use LZMA Compression algorithm, compression quality is better.

OutFile "slimevr_web_installer.exe"

# Define installation directory
InstallDir "$PROGRAMFILES\SlimeVR Server" ; $InstDir default value. Defaults to user's local appdata to avoid asking admin rights

# Admin rights are required for:
# 1. Removing Start Menu shortcut in Windows 7
# 2. Adding/removing firewall rule
# 3. USB drivers installation
RequestExecutionLevel admin

# Detect Steam installation and prevent installation if none found
Var /GLOBAL SteamPath
Function .onInit
    ${If} ${RunningX64}
        ReadRegStr $0 HKLM SOFTWARE\WOW6432Node\Valve\Steam InstallPath
    ${Else}
        ReadRegStr $0 HKLM SOFTWARE\Valve\Steam InstallPath
    ${EndIf}
    ${If} $0 == ""
        MessageBox MB_OK "No Steam installation folder detected."
        Abort
    ${EndIf}
    StrCpy $SteamPath $0
FunctionEnd

# Detect Steam installation and just write path that we need to remove during uninstall (if present)
Function un.onInit
    ${If} ${RunningX64}
        ReadRegStr $0 HKLM SOFTWARE\WOW6432Node\Valve\Steam InstallPath
    ${Else}
        ReadRegStr $0 HKLM SOFTWARE\Valve\Steam InstallPath
    ${EndIf}
    StrCpy $SteamPath $0
FunctionEnd

# Init functions start #
# Clean up on exit
Function .onGUIEnd
    Delete "$TEMP\slimevr-openvr-driver-win64.zip"
    Delete "$TEMP\SlimeVR.zip"
    Delete "$TEMP\OpenJDK11U-jre_x64_windows_hotspot_11.0.12_7.zip"
    Delete "$TEMP\OpenJDK11U-jre_x86-32_windows_hotspot_11.0.12_7.zip"
    RMDir /r "$TEMP\slimevr-openvr-driver-win64"
    RMDir /r "$TEMP\SlimeVR"
    RMDir /r "$TEMP\OpenJDK11U-jre_x86-32_windows_hotspot_11.0.12_7"
    RMDir /r "$TEMP\OpenJDK11U-jre_x64_windows_hotspot_11.0.12_7"
    RMDir /r "$TEMP\slimevr_usb_drivers_inst"
FunctionEnd

!macro cleanInstDir un
Function ${un}cleanInstDir
    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\run.bat"
    Delete "$INSTDIR\run.ico"
    Delete "$INSTDIR\slimevr.jar"
    Delete "$INSTDIR\firewall*.bat"
    Delete "$INSTDIR\MagnetoLib.dll"
    Delete "$INSTDIR\steamvr.ps1"
    Delete "$INSTDIR\log*"
    Delete "$INSTDIR\*.log"
    Delete "$INSTDIR\vrconfig.yml"
    Delete "$INSTDIR\LICENSE"

    RMdir /r "$INSTDIR\jre"
    RMdir /r "$INSTDIR\driver"
    RMDir /r "$INSTDIR\logs"

    RMDir $INSTDIR
FunctionEnd
!macroend

!insertmacro cleanInstDir ""
!insertmacro cleanInstDir "un."
# Init functions end #

Page Custom startPage
Page Custom steamVrDirectoryPage
Page Directory dirPre ; This page might change $InstDir
Page InstFiles

Var Dialog
Var Label
Var /GLOBAL hasExistingInstall
Var /GLOBAL steamVrDirectory
Var /GLOBAL DESTTEXT
Var /GLOBAL DEST
var /GLOBAL BROWSEDEST

Function startPage

    nsDialogs::Create 1018
    Pop $Dialog

    ${If} $Dialog == error
        Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 12u "Welcome to SlimeVR Installer!"
    Pop $Label

    ReadRegStr $hasExistingInstall HKLM Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR InstallPath
    ${If} $hasExistingInstall != ""
        ${NSD_CreateLabel} 0 15u 100% 50u "An existing installation was detected in $hasExistingInstall. The installer will update it. Click Next to proceed with update."
        Pop $Label
        StrCpy $hasExistingInstall $INSTDIR
    ${Else}
        ${NSD_CreateLabel} 0 15u 100% 50u "Click Next to proceed with installation."
        Pop $Label
    ${EndIf}

    nsDialogs::Show

FunctionEnd

Function steamVrDirectoryPage

    # If powershell is present - rely on automatic detection.
    ${DisableX64FSRedirection}
    nsExec::Exec "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe Get-Host" $0
    ${EnableX64FSRedirection}
    Pop $0
    ${If} $0 == 0
        Abort
    ${Endif}

    #Create Dialog and quit if error
    nsDialogs::Create 1018
    Pop $Dialog
    ${If} $Dialog == error
        Abort
    ${EndIf}

    StrCpy $steamVrDirectory "$SteamPath\steamapps\common\SteamVR"
    ${NSD_CreateLabel} 0 0 100% 20u "Specify a path to your SteamVR installation by clicking Browse. Then click Next to proceed with installation."
    ${NSD_CreateLabel} 0 60 100% 12u "Destination"
    ${NSD_CreateText} 0 80 80% 12u "$SteamPath\steamapps\common\SteamVR"
    pop $DESTTEXT
    ${NSD_CreateBrowseButton} 320 80 20% 12u "Browse"
    pop $BROWSEDEST

    ${NSD_OnClick} $BROWSEDEST Browsedest

    nsDialogs::Show
FunctionEnd

Function Browsedest
    nsDialogs::SelectFolderDialog "Select SteamVR installation folder" "$SteamPath\steamapps\common\SteamVR"
    Pop $DEST
    ${If} $DEST == error
        Abort
    ${Endif}
    StrCpy $steamVrDirectory $DEST
    ${NSD_SetText} $DESTTEXT $DEST
FunctionEnd

# Pre-hook for directory selection function
Function dirPre
    # Skip directory selection if existing installation was detected
    ${If} $hasExistingInstall != ""
        Abort
    ${EndIf}
FunctionEnd

# InstFiles section start
Section
    ${If} $hasExistingInstall == ""
        Var /GLOBAL DownloadedJreFile
        DetailPrint "Downloading Java JRE..."
        ${If} ${RunningX64}
            NScurl::http GET "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.12%2B7/OpenJDK11U-jre_x64_windows_hotspot_11.0.12_7.zip" "$TEMP\OpenJDK11U-jre_x64_windows_hotspot_11.0.12_7.zip" /CANCEL /RESUME /END
            StrCpy $DownloadedJreFile "OpenJDK11U-jre_x64_windows_hotspot_11.0.12_7"
        ${Else}
            NScurl::http GET "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.12%2B7/OpenJDK11U-jre_x86-32_windows_hotspot_11.0.12_7.zip" "$TEMP\OpenJDK11U-jre_x86-32_windows_hotspot_11.0.12_7.zip" /CANCEL /RESUME /END
            StrCpy $DownloadedJreFile "OpenJDK11U-jre_x86-32_windows_hotspot_11.0.12_7"
        ${EndIf}
        Pop $0 ; Status text ("OK" for success)
        ${If} $0 != "OK"
            Abort "Failed to download Java JRE. Reason: $0."
        ${EndIf}
        DetailPrint "Downloaded!"
    ${Endif}

    DetailPrint "Downloading SlimeVR Driver..."
    NScurl::http GET "https://github.com/SlimeVR/SlimeVR-OpenVR-Driver/releases/latest/download/slimevr-openvr-driver-win64.zip" "$TEMP\slimevr-openvr-driver-win64.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download SlimeVR Driver. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    DetailPrint "Downloading SlimeVR Server..."
    NScurl::http GET "https://github.com/SlimeVR/SlimeVR-Server/releases/latest/download/SlimeVR.zip" "$TEMP\SlimeVR.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download SlimeVR Server. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    DetailPrint "Unpacking downloaded files..."
    nsisunz::Unzip "$TEMP\slimevr-openvr-driver-win64.zip" "$TEMP\slimevr-openvr-driver-win64\"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    nsisunz::Unzip "$TEMP\SlimeVR.zip" "$TEMP\SlimeVR\"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    ${If} $hasExistingInstall == ""
        DetailPrint "Installing USB drivers...."

        # CP210X drivers (NodeMCU v2)
        SetOutPath "$TEMP\slimevr_usb_drivers_inst\CP201x"
        DetailPrint "Installing CP210x driver..."
        File /r "CP201x\*"
        ${DisableX64FSRedirection}
        nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "$TEMP\slimevr_usb_drivers_inst\CP201x\silabser.inf"' $0
        Pop $0
        ${EnableX64FSRedirection}
        ${If} $0 == 0
            DetailPrint "Success!"
        ${ElseIf} $0 == 259
            DetailPrint "No devices match the supplied driver or the target device is already using a better or newer driver than the driver specified for installation."
        ${ElseIf} $0 == 3010
            DetailPrint "The requested operation completed successfully and a system reboot is required."
        ${Else}
            Abort "Failed to install CP210x driver. Error code: $0."
        ${Endif}

        # CH340 drivers (NodeMCU v3)
        SetOutPath "$TEMP\slimevr_usb_drivers_inst\CH341SER"
        DetailPrint "Installing CH340 driver..."
        File /r "CH341SER\*"
        ${DisableX64FSRedirection}
        nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "$TEMP\slimevr_usb_drivers_inst\CH341SER\CH341SER.INF"' $0
        Pop $0
        ${EnableX64FSRedirection}
        ${If} $0 == 0
            DetailPrint "Success!"
        ${ElseIf} $0 == 259
            DetailPrint "No devices match the supplied driver or the target device is already using a better or newer driver than the driver specified for installation."
        ${ElseIf} $0 == 3010
            DetailPrint "The requested operation completed successfully and a system reboot is required."
        ${Else}
            Abort "Failed to install CP210x driver. Error code: $0."
        ${Endif}
    ${Endif}

    # Set the installation directory as the destination for the following actions
    SetOutPath $INSTDIR

    ${If} $hasExistingInstall == ""
        DetailPrint "Unzipping Java JRE to installation folder...."
        nsisunz::Unzip "$TEMP\$DownloadedJreFile.zip" "$TEMP\$DownloadedJreFile\"
        Pop $0
        DetailPrint "Unzipping finished with $0."
        CopyFiles /SILENT "$TEMP\$DownloadedJreFile\jdk-11.0.12+7-jre\*" "$INSTDIR\jre"
    ${Endif}

    DetailPrint "Copying SlimeVR Server to installation folder..."
    CopyFiles /SILENT "$TEMP\SlimeVR\SlimeVR\*" $INSTDIR

    # Include modified run.bat that will run bundled JRE
    File "run.bat"
    File "run.ico"
    # Include SteamVR powershell script to register/unregister driver
    File "steamvr.ps1"

    DetailPrint "Copying SlimeVR Driver to SteamVR..."
    ${If} $steamVrDirectory == ""
        ${DisableX64FSRedirection}
        nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$SteamPath" -DriverPath "$TEMP\slimevr-openvr-driver-win64\slimevr"' $0
        ${EnableX64FSRedirection}
        Pop $0
        Pop $1
        ${If} $0 != 0
            ${If} $hasExistingInstall == ""
                Call cleanInstDir
            ${Endif}
            Abort "Failed to copy SlimeVR Driver. Make sure you have SteamVR installed."
        ${EndIf}
        DetailPrint $1
    ${Else}
        CopyFiles /SILENT "$TEMP\slimevr-openvr-driver-win64\slimevr" "$steamVrDirectory\drivers"
    ${Endif}

    ${If} $hasExistingInstall == ""
        DetailPrint "Adding SlimeVR Server to firewall exceptions...."
        nsExec::Exec '"$INSTDIR\firewall.bat"'
    ${Endif}

    ${If} $hasExistingInstall == ""
        DetailPrint "Creating shortcuts..."
        CreateDirectory "$SMPROGRAMS\SlimeVR Server"
        CreateShortcut "$SMPROGRAMS\SlimeVR Server\Uninstall SlimeVR Server.lnk" "$INSTDIR\uninstall.exe"
        CreateShortcut "$SMPROGRAMS\SlimeVR Server\SlimeVR Server.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\run.ico"
        CreateShortcut "$DESKTOP\SlimeVR Server.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\run.ico"

        DetailPrint "Registering installation..."
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "InstallPath" "$\"$INSTDIR$\""
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "DisplayName" "SlimeVR"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "DisplayIcon" "$\"$INSTDIR\run.ico$\""
    ${EndIf}

    # Create the uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"

    # Grant all users full access to the installation folder to avoid using elevated rights
    # when installing to folders with limited access
    AccessControl::GrantOnFile $INSTDIR "(BU)" "FullAccess"
    Pop $0
SectionEnd
# InstFiles section end

# Uninstaller section start
Section "uninstall"
    ${DisableX64FSRedirection}
    nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$SteamPath" -DriverPath "slimevr" -Uninstall"' $0
    ${EnableX64FSRedirection}
    Pop $0
    Pop $1
    DetailPrint $1

    # Remove the shortcuts
    RMdir /r "$SMPROGRAMS\SlimeVR Server"
    # Remove separate shortcuts introduced with first release
    Delete "$SMPROGRAMS\Uninstall SlimeVR Server.lnk"
    Delete "$SMPROGRAMS\SlimeVR Server.lnk"
    Delete "$DESKTOP\SlimeVR Server.lnk"

    DetailPrint "Removing SlimeVR Server from firewall exceptions...."
    nsExec::Exec '"$INSTDIR\firewall_uninstall.bat"'

    DetailPrint "Unregistering installation..."
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR"

    Call un.cleanInstDir

    DetailPrint "Done."
SectionEnd
# Uninstaller section end