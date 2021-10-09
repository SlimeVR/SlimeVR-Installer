Unicode True

!include x64.nsh 		; For RunningX64 check
!include LogicLib.nsh	; For conditional operators
!include nsDialogs.nsh  ; For custom pages
!include FileFunc.nsh   ; For GetTime function

# Define name of installer
Name SlimeVR Installer

SpaceTexts none # Don't show required disk space since we don't know for sure
SetOverwrite on
SetCompressor lzma  # Use LZMA Compression algorithm, compression quality is better.

OutFile "slimevr_web_installer.exe"

# Define installation directory
InstallDir "$PROGRAMFILES\SlimeVR Server" ; $InstDir default value. Defaults to user's local appdata to avoid asking admin rights

# Admin rights are required for:
# 1. Removing Start Menu shortcut in Windows 7+
# 2. Adding/removing firewall rules
# 3. USB drivers installation
RequestExecutionLevel admin

# Start page installer actions
Var REPAIR
Var UPDATE
Var SELECTED_INSTALLER_ACTION

# End page actions
Var CREATE_DESKTOP_SHORTCUT
Var CREATE_STARTMENU_SHORTCUTS
Var DOCUMENTATION_LINK

# Detected Steam folder
Var STEAMDIR

# Detected or specified SteamVR folder
Var STEAMVRDIR
Var STEAMVRDIR_TEXT
Var STEAMVRDIR_DEST

# Init functions start #
# Detect Steam installation and prevent installation if none found
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
    StrCpy $STEAMDIR $0
FunctionEnd

# Detect Steam installation and just write path that we need to remove during uninstall (if present)
Function un.onInit
    ${If} ${RunningX64}
        ReadRegStr $0 HKLM SOFTWARE\WOW6432Node\Valve\Steam InstallPath
    ${Else}
        ReadRegStr $0 HKLM SOFTWARE\Valve\Steam InstallPath
    ${EndIf}
    StrCpy $STEAMDIR $0
FunctionEnd

# Clean up on exit
Function cleanTemp
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

Function .onGUIEnd
    Call cleanTemp
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

Page Custom startPage startPageLeave
Page Directory dirPre ; This page might change $InstDir
Page Custom steamVrDirectoryPage
Page InstFiles cleanTemp ; Clean temp on pre-install to avoid any leftover files failing the installation, temp files will be removed in .onGUIEnd
Page Custom endPage endPageLeave

UninstPage UninstConfirm
UninstPage InstFiles

Function startPage

    nsDialogs::Create 1018
    Pop $0

    ${If} $0 == error
        Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 12u "Welcome to SlimeVR Installer!"
    Pop $0

    ReadRegStr $0 HKLM Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR InstallLocation
    ${If} $0 != ""
        StrCpy $INSTDIR $0

        ${NSD_CreateLabel} 0 15u 100% 20u 'An existing installation was detected in "$0". Choose an option and click Next to proceed.'
        ${NSD_CreateRadioButton} 0 40u 100% 10u "Update"
        Pop $UPDATE
        ${NSD_CreateRadioButton} 0 55u 100% 10u "Repair"
        Pop $REPAIR

        ${If} $SELECTED_INSTALLER_ACTION == "update"
            SendMessage $UPDATE ${BM_SETCHECK} 1 0
        ${ElseIf} $SELECTED_INSTALLER_ACTION == "repair"
            SendMessage $REPAIR ${BM_SETCHECK} 1 0
        ${Else}
            SendMessage $UPDATE ${BM_SETCHECK} 1 0
        ${EndIf}
    ${Else}
        ${NSD_CreateLabel} 0 15u 100% 50u "Click Next to proceed with installation."
        Pop $0
    ${EndIf}

    nsDialogs::Show

FunctionEnd

Function startPageLeave

  ${NSD_GetState} $UPDATE $0
  ${NSD_GetState} $REPAIR $1

  ${If} $0 = 1
    StrCpy $SELECTED_INSTALLER_ACTION "update"
  ${ElseIf} $1 = 1
    StrCpy $SELECTED_INSTALLER_ACTION "repair"
  ${EndIf}

FunctionEnd

Function endPage

    nsDialogs::Create 1018
    Pop $0

    ${If} $0 == error
        Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 12u "The installation is finished!"
    Pop $0

    ${NSD_CreateLink} 0 15u 100% 20u 'For further instructions, click here to visit the documentation.'
    Pop $DOCUMENTATION_LINK
    ${NSD_OnClick} $DOCUMENTATION_LINK openDocumentationLink

    ${If} $SELECTED_INSTALLER_ACTION != "update"
        ${NSD_CreateCheckbox} 0 40u 100% 10u "Create Desktop shortcut"
        Pop $CREATE_DESKTOP_SHORTCUT
        ${NSD_Check} $CREATE_DESKTOP_SHORTCUT
        ${NSD_CreateCheckbox} 0 55u 100% 10u "Create Start Menu shortcuts"
        Pop $CREATE_STARTMENU_SHORTCUTS
        ${NSD_Check} $CREATE_STARTMENU_SHORTCUTS
    ${Endif}

    nsDialogs::Show

FunctionEnd

Function openDocumentationLink
    Pop $0
    ExecShell "open" "https://docs.slimevr.dev/slimevr-setup.html"
FunctionEnd

Function endPageLeave

  ${NSD_GetState} $CREATE_DESKTOP_SHORTCUT $0
  ${NSD_GetState} $CREATE_STARTMENU_SHORTCUTS $1

    ${If} $0 = 1
        CreateDirectory "$SMPROGRAMS\SlimeVR Server"
        CreateShortcut "$SMPROGRAMS\SlimeVR Server\Uninstall SlimeVR Server.lnk" "$INSTDIR\uninstall.exe"
        CreateShortcut "$SMPROGRAMS\SlimeVR Server\SlimeVR Server.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\run.ico"
    ${Endif}
    ${If} $1 = 1
        CreateShortcut "$DESKTOP\SlimeVR Server.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\run.ico"
    ${EndIf}

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
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    StrCpy $STEAMVRDIR "$STEAMDIR\steamapps\common\SteamVR"
    ${NSD_CreateLabel} 0 0 100% 20u "Specify a path to your SteamVR installation by clicking Browse. Then click Install to proceed with installation."
    ${NSD_CreateLabel} 0 60 100% 12u "Destination folder:"
    ${NSD_CreateText} 0 80 80% 12u "$STEAMDIR\steamapps\common\SteamVR"
    Pop $STEAMVRDIR_TEXT
    ${NSD_CreateBrowseButton} 320 80 20% 12u "Browse"
    Pop $0

    ${NSD_OnClick} $0 browseDest

    nsDialogs::Show
FunctionEnd

Function browseDest
    nsDialogs::SelectFolderDialog "Select SteamVR installation folder" "$STEAMDIR\steamapps\common\SteamVR"
    Pop $STEAMVRDIR_DEST
    ${If} $STEAMVRDIR_DEST == error
        Abort
    ${Endif}
    StrCpy $STEAMVRDIR $STEAMVRDIR_DEST
    ${NSD_SetText} $STEAMVRDIR_TEXT $STEAMVRDIR_DEST
FunctionEnd

# Pre-hook for directory selection function
Function dirPre
    # Skip directory selection if existing installation was detected and user selected an action
    ${If} $SELECTED_INSTALLER_ACTION != ""
        Abort
    ${EndIf}
FunctionEnd

# GetTime function macro to get datetime
!insertmacro GetTime

# InstFiles section start
Section
    ${If} $SELECTED_INSTALLER_ACTION != "update"
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

    ${If} $SELECTED_INSTALLER_ACTION != "update"
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

    ${If} $SELECTED_INSTALLER_ACTION != "update"
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
    ${If} $STEAMVRDIR == ""
        ${DisableX64FSRedirection}
        nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$STEAMDIR" -DriverPath "$TEMP\slimevr-openvr-driver-win64\slimevr"' $0
        ${EnableX64FSRedirection}
        Pop $0
        ${If} $0 != 0
            ${If} $SELECTED_INSTALLER_ACTION != "update"
                Call cleanInstDir
            ${Endif}
            Abort "Failed to copy SlimeVR Driver. Make sure you have SteamVR installed."
        ${EndIf}
    ${Else}
        CopyFiles /SILENT "$TEMP\slimevr-openvr-driver-win64\slimevr" "$STEAMVRDIR\drivers\slimevr"
    ${Endif}

    ${If} $SELECTED_INSTALLER_ACTION == "repair"
        DetailPrint "Removing SlimeVR Server from firewall exceptions...."
        nsExec::Exec '"$INSTDIR\firewall_uninstall.bat"'
    ${Endif}

    ${If} $SELECTED_INSTALLER_ACTION != "update"
        DetailPrint "Adding SlimeVR Server to firewall exceptions...."
        nsExec::Exec '"$INSTDIR\firewall.bat"'
    ${Endif}

    ${If} $SELECTED_INSTALLER_ACTION != "update"
        DetailPrint "Registering installation..."
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "InstallLocation" "$INSTDIR"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "DisplayName" "SlimeVR"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "UninstallString" '"$INSTDIR\uninstall.exe"'
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "DisplayIcon" "$INSTDIR\run.ico"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "HelpLink" "https://docs.slimevr.dev/"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "URLInfoAbout" "https://slimevr.dev/"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                        "URLUpdateInfo" "https://github.com/SlimeVR/SlimeVR-Installer/releases"
    ${EndIf}
    ${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "InstallDate" "$2$1$0"

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
    nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$STEAMDIR" -DriverPath "slimevr" -Uninstall' $0
    ${EnableX64FSRedirection}
    Pop $0

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