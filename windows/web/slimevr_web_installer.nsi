Unicode True

!include x64.nsh 		; For RunningX64 check
!include LogicLib.nsh	; For conditional operators
!include nsDialogs.nsh  ; For custom pages
!include FileFunc.nsh   ; For GetTime function
!include MUI2.nsh

!define MUI_ICON "run.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "logo.bmp"
!define MUI_HEADERIMAGE_BITMAP_STRETCH "NoStretchNoCrop"
!define MUI_HEADERIMAGE_RIGHT

# Define name of installer
Name "SlimeVR"

SpaceTexts none # Don't show required disk space since we don't know for sure
SetOverwrite on
SetCompressor lzma  # Use LZMA Compression algorithm, compression quality is better.

OutFile "slimevr_web_installer.exe"

# Define installation directory
InstallDir "$PROGRAMFILES\SlimeVR Server" ; $InstDir default value. Defaults to user's local appdata to avoid asking admin rights

ShowInstDetails show
ShowUninstDetails show

BrandingText "SlimeVR Installer 0.1.5"

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
Var OPEN_DOCUMENTATION

# Detected Steam folder
Var STEAMDIR

# Detected or specified SteamVR folder
Var STEAMVRDIR
Var STEAMVRDIR_TEXT
Var STEAMVRDIR_DEST

# Init functions start #
# Detect Steam installation and prevent installation if none found
Function .onInit
    InitPluginsDir
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
    Delete "$TEMP\OpenJDK11U-jre_x64_windows_hotspot_11.0.14_9.zip"
    Delete "$TEMP\OpenJDK11U-jre_x86-32_windows_hotspot_11.0.14_9.zip"
    Delete "$TEMP\slimevr-ui.exe"
    Delete "$TEMP\SlimeVR-Feeder-App-win64.zip"
    RMDir /r "$TEMP\slimevr-openvr-driver-win64"
    RMDir /r "$TEMP\SlimeVR"
    RMDir /r "$TEMP\OpenJDK11U-jre_x86-32_windows_hotspot_11.0.14_9"
    RMDir /r "$TEMP\OpenJDK11U-jre_x64_windows_hotspot_11.0.14_9"
    RMDir /r "$TEMP\slimevr_usb_drivers_inst"
    RMDir /r "$TEMP\SlimeVR-Feeder-App-win64"
FunctionEnd

Function .onInstFailed
    ${If} $SELECTED_INSTALLER_ACTION == ""
        Call cleanInstDir
    ${Endif}
FunctionEnd

Function .onGUIEnd
    Call cleanTemp
FunctionEnd

Function cleanInstDir
    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\run.bat"
    Delete "$INSTDIR\run.ico"
    Delete "$INSTDIR\slimevr.jar"
    Delete "$INSTDIR\firewall*.bat"
    Delete "$INSTDIR\MagnetoLib.dll"
    Delete "$INSTDIR\steamvr.ps1"
    Delete "$INSTDIR\log*"
    Delete "$INSTDIR\*.log"
    Delete "$INSTDIR\*.lck"
    Delete "$INSTDIR\vrconfig.yml"
    Delete "$INSTDIR\LICENSE*"

    RMDir /r "$INSTDIR\Recordings"
    RMdir /r "$INSTDIR\jre"
    RMdir /r "$INSTDIR\driver"
    RMDir /r "$INSTDIR\logs"
    RMdir /r "$INSTDIR\Feeder-App"

    Delete "$INSTDIR\slimevr-ui.exe"

    RMDir $INSTDIR
FunctionEnd
# Init functions end #

Page Custom startPage startPageLeave

!define MUI_PAGE_CUSTOMFUNCTION_PRE componentsPre
!insertmacro MUI_PAGE_COMPONENTS

!define MUI_PAGE_CUSTOMFUNCTION_PRE installerActionPre
!insertmacro MUI_PAGE_DIRECTORY

Page Custom steamVrDirectoryPage

!define MUI_PAGE_CUSTOMFUNCTION_PRE cleanTemp ; Clean temp on pre-install to avoid any leftover files failing the installation, temp files will be removed in .onGUIEnd
!insertmacro MUI_PAGE_INSTFILES

Page Custom endPage endPageLeave

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

LangString START_PAGE_TITLE ${LANG_ENGLISH} "Welcome"
LangString START_PAGE_SUBTITLE ${LANG_ENGLISH} "Welcome to SlimeVR Setup!"

Function startPage
    !insertmacro MUI_HEADER_TEXT $(START_PAGE_TITLE) $(START_PAGE_SUBTITLE)
    nsDialogs::Create 1018
    Pop $0

    ${If} $0 == error
        Abort
    ${EndIf}

    ReadRegStr $0 HKLM Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR InstallLocation
    ${If} $0 != ""
        StrCpy $INSTDIR $0

        ${NSD_CreateLabel} 0 0 100% 20u 'An existing installation was detected in "$0". Choose an option and click Next to proceed.'
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
        ${NSD_CreateLabel} 0 0 100% 50u "Click Next to proceed with installation."
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

    ${NSD_CreateCheckbox} 0 25u 100% 10u "Open SlimeVR documentation"
    Pop $OPEN_DOCUMENTATION
    ${NSD_Check} $OPEN_DOCUMENTATION

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

Function endPageLeave

    SetOutPath $INSTDIR

    ${NSD_GetState} $CREATE_STARTMENU_SHORTCUTS $0
    ${NSD_GetState} $CREATE_DESKTOP_SHORTCUT $1
    ${NSD_GetState} $OPEN_DOCUMENTATION $2

    ${If} $0 = 1
        CreateDirectory "$SMPROGRAMS\SlimeVR Server"
        CreateShortcut "$SMPROGRAMS\SlimeVR Server\Uninstall SlimeVR Server.lnk" "$INSTDIR\uninstall.exe"
        CreateShortcut "$SMPROGRAMS\SlimeVR Server\SlimeVR Server.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\run.ico"
    ${Endif}
    ${If} $1 = 1
        CreateShortcut "$DESKTOP\SlimeVR Server.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\run.ico"
    ${EndIf}
    ${If} $2 = 1
        ExecShell "open" "https://docs.slimevr.dev/server-setup/slimevr-setup.html"
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
Function installerActionPre
    # Skip directory selection if existing installation was detected and user selected an action
    ${If} $SELECTED_INSTALLER_ACTION != ""
        Abort
    ${EndIf}
FunctionEnd

# GetTime function macro to get datetime
!insertmacro GetTime

Function DumpLog
  Exch $5
  Push $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $6

  FindWindow $0 "#32770" "" $HWNDPARENT
  GetDlgItem $0 $0 1016
  StrCmp $0 0 exit
  FileOpen $5 $5 "w"
  StrCmp $5 "" exit
    SendMessage $0 ${LVM_GETITEMCOUNT} 0 0 $6
    System::Alloc ${NSIS_MAX_STRLEN}
    Pop $3
    StrCpy $2 0
    System::Call "*(i, i, i, i, i, i, i, i, i) i \
      (0, 0, 0, 0, 0, r3, ${NSIS_MAX_STRLEN}) .r1"
    loop: StrCmp $2 $6 done
      System::Call "User32::SendMessageA(i, i, i, i) i \
        ($0, ${LVM_GETITEMTEXT}, $2, r1)"
      System::Call "*$3(&t${NSIS_MAX_STRLEN} .r4)"
      FileWrite $5 "$4$\r$\n"
      IntOp $2 $2 + 1
      Goto loop
    done:
      FileClose $5
      System::Free $1
      System::Free $3
  exit:
    Pop $6
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
    Exch $5
FunctionEnd

Section "-" SEC_JRE
    Var /GLOBAL DownloadedJreFile
    DetailPrint "Downloading Java JRE..."
    ${If} ${RunningX64}
        NScurl::http GET "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.14%2B9/OpenJDK11U-jre_x64_windows_hotspot_11.0.14_9.zip" "$TEMP\OpenJDK11U-jre_x64_windows_hotspot_11.0.14_9.zip" /CANCEL /RESUME /END
        StrCpy $DownloadedJreFile "OpenJDK11U-jre_x64_windows_hotspot_11.0.14_9"
    ${Else}
        NScurl::http GET "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.14%2B9/OpenJDK11U-jre_x86-32_windows_hotspot_11.0.14_9.zip" "$TEMP\OpenJDK11U-jre_x86-32_windows_hotspot_11.0.14_9.zip" /CANCEL /RESUME /END
        StrCpy $DownloadedJreFile "OpenJDK11U-jre_x86-32_windows_hotspot_11.0.14_9"
    ${EndIf}
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download Java JRE. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    DetailPrint "Unzipping Java JRE to installation folder...."
    nsisunz::Unzip "$TEMP\$DownloadedJreFile.zip" "$TEMP\$DownloadedJreFile\"
    Pop $0
    DetailPrint "Unzipping finished with $0."
    CopyFiles /SILENT "$TEMP\$DownloadedJreFile\jdk-11.0.14+9-jre\*" "$INSTDIR\jre"
SectionEnd

Section "SlimeVR Server" SEC_SERVER
    SectionIn RO

    SetOutPath $INSTDIR

    DetailPrint "Downloading SlimeVR Server..."
    NScurl::http GET "https://github.com/SlimeVR/SlimeVR-Server/releases/latest/download/SlimeVR.zip" "$TEMP\SlimeVR.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download SlimeVR Server. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    nsisunz::Unzip "$TEMP\SlimeVR.zip" "$TEMP\SlimeVR\"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    DetailPrint "Copying SlimeVR Server to installation folder..."
    CopyFiles /SILENT "$TEMP\SlimeVR\SlimeVR\*" $INSTDIR

    # Include modified run.bat that will run bundled JRE
    File "run.bat"
    File "run.ico"

    # Create the uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "SlimeVR GUI" SEC_SERVER_GUI
    SectionIn RO

    SetOutPath $INSTDIR

    DetailPrint "Downloading SlimeVR GUI ..."
    NScurl::http GET "https://github.com/Futurabeast/slimevr-ui/releases/download/0.0.1/slimevr-ui.exe" "$TEMP\slimevr-ui.exe" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download SlimeVR GUI. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    nsisunz::Unzip "$TEMP\slimevr-ui.exe" "$TEMP"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    DetailPrint "Copying SlimeVR GUI to installation folder..."
    CopyFiles /SILENT "$TEMP\slimevr-ui.exe" $INSTDIR
SectionEnd

Section "SlimeVR Driver" SEC_VRDRIVER
    SectionIn RO

    SetOutPath $INSTDIR

    DetailPrint "Downloading SlimeVR Driver..."
    NScurl::http GET "https://github.com/SlimeVR/SlimeVR-OpenVR-Driver/releases/latest/download/slimevr-openvr-driver-win64.zip" "$TEMP\slimevr-openvr-driver-win64.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download SlimeVR Driver. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    DetailPrint "Unpacking downloaded files..."
    nsisunz::Unzip "$TEMP\slimevr-openvr-driver-win64.zip" "$TEMP\slimevr-openvr-driver-win64\"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    # Include SteamVR powershell script to register/unregister driver
    File "steamvr.ps1"

    DetailPrint "Copying SlimeVR Driver to SteamVR..."
    ${If} $STEAMVRDIR == ""
        ${DisableX64FSRedirection}
        nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$STEAMDIR" -DriverPath "$TEMP\slimevr-openvr-driver-win64\slimevr"' $0
        ${EnableX64FSRedirection}
        Pop $0
        ${If} $0 != 0
            Abort "Failed to copy SlimeVR Driver."
        ${EndIf}
    ${Else}
        CopyFiles /SILENT "$TEMP\slimevr-openvr-driver-win64\slimevr" "$STEAMVRDIR\drivers\slimevr"
    ${Endif}
SectionEnd

Section "SlimeVR Feeder App" SEC_FEEDER_APP
    SetOutPath $INSTDIR

    DetailPrint "Downloading SlimeVR Feeder App..."
    NScurl::http GET "https://github.com/SlimeVR/SlimeVR-Feeder-App/releases/latest/download/SlimeVR-Feeder-App-win64.zip" "$TEMP\SlimeVR-Feeder-App-win64.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download SlimeVR Feeder App. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    DetailPrint "Unpacking downloaded files..."
    nsisunz::Unzip "$TEMP\SlimeVR-Feeder-App-win64.zip" "$TEMP"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    DetailPrint "Copying SlimeVR Feeder App..."
    CopyFiles /SILENT "$TEMP\SlimeVR-Feeder-App-win64\*" "$INSTDIR\Feeder-App"

    DetailPrint "Installing SlimeVR Feeder App driver..."
    nsExec::ExecToLog '"$INSTDIR\Feeder-App\SlimeVR-Feeder-App.exe" --install'
SectionEnd

SectionGroup "USB drivers" SEC_USBDRIVERS

    Section "CP210x driver" SEC_CP210X
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
    SectionEnd

    Section "CH340 driver" SEC_CH340
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
            Abort "Failed to install CH340 driver. Error code: $0."
        ${Endif}
    SectionEnd

    Section /o "CH9102x driver" SEC_CH9102X
        # CH343 drivers (NodeMCU v2.1, some NodeMCU v3?)
        SetOutPath "$TEMP\slimevr_usb_drivers_inst\CH343SER"
        DetailPrint "Installing CH910x driver..."
        File /r "CH343SER\*"
        ${DisableX64FSRedirection}
        nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "$TEMP\slimevr_usb_drivers_inst\CH343SER\CH343SER.INF"' $0
        Pop $0
        ${EnableX64FSRedirection}
        ${If} $0 == 0
            DetailPrint "Success!"
        ${ElseIf} $0 == 259
            DetailPrint "No devices match the supplied driver or the target device is already using a better or newer driver than the driver specified for installation."
        ${ElseIf} $0 == 3010
            DetailPrint "The requested operation completed successfully and a system reboot is required."
        ${Else}
            Abort "Failed to install CH910x driver. Error code: $0."
        ${Endif}
    SectionEnd

SectionGroupEnd

Section "-" SEC_FIREWALL
    ${If} $SELECTED_INSTALLER_ACTION == "repair"
        DetailPrint "Removing SlimeVR Server from firewall exceptions...."
        nsExec::Exec '"$INSTDIR\firewall_uninstall.bat"'
    ${Endif}

    DetailPrint "Adding SlimeVR Server to firewall exceptions...."
    nsExec::Exec '"$INSTDIR\firewall.bat"'
SectionEnd

Section "-" SEC_REGISTERAPP
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
SectionEnd

Section
    # Grant all users full access to the installation folder to avoid using elevated rights
    # when installing to folders with limited access
    AccessControl::GrantOnFile $INSTDIR "(BU)" "FullAccess"
    Pop $0

    # Add/update installation date
    ${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "InstallDate" "$2$1$0"

    # Write install.log
    StrCpy $0 "$INSTDIR\install.log"
    Push $0
    Call DumpLog
SectionEnd

Function componentsPre
    ${If} $SELECTED_INSTALLER_ACTION == "update"
        SectionSetFlags ${SEC_FIREWALL} 0
        SectionSetFlags ${SEC_JRE} 0
        SectionSetFlags ${SEC_REGISTERAPP} 0
        SectionSetFlags ${SEC_USBDRIVERS} ${SF_SECGRP}
        SectionSetFlags ${SEC_VRDRIVER} ${SF_SELECTED}
        SectionSetFlags ${SEC_SERVER} ${SF_SELECTED}
    ${EndIf}
FunctionEnd

Section "-un.SlimeVR Server" un.SEC_SERVER
    # Remove the shortcuts
    RMdir /r "$SMPROGRAMS\SlimeVR Server"
    # Remove separate shortcuts introduced with first release
    Delete "$SMPROGRAMS\Uninstall SlimeVR Server.lnk"
    Delete "$SMPROGRAMS\SlimeVR Server.lnk"
    Delete "$DESKTOP\SlimeVR Server.lnk"

    Delete "$INSTDIR\run.bat"
    Delete "$INSTDIR\run.ico"
    Delete "$INSTDIR\slimevr.jar"
    Delete "$INSTDIR\slimevr-ui.exe"
    Delete "$INSTDIR\MagnetoLib.dll"
    Delete "$INSTDIR\log*"
    Delete "$INSTDIR\*.log"
    Delete "$INSTDIR\*.lck"
    Delete "$INSTDIR\vrconfig.yml"
    Delete "$INSTDIR\LICENSE*"

    RMDir /r "$INSTDIR\Recordings"
    RMdir /r "$INSTDIR\jre"
    RMDir /r "$INSTDIR\logs"

    IfErrors fail success
    fail:
        DetailPrint "Failed to remove SlimeVR Server files. Make sure SlimeVR Server is closed."
        Abort
    success:
SectionEnd

Section "-un.SlimeVR Gui" un.SEC_SERVER_GUI
    Delete "$INSTDIR\slimevr-ui.exe"
SectionEnd

Section "-un.SlimeVR Driver" un.SEC_VRDRIVER
    ${DisableX64FSRedirection}
    nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$STEAMDIR" -DriverPath "slimevr" -Uninstall' $0
    ${EnableX64FSRedirection}
    Pop $0
    ${If} $0 != 0
        Abort "Failed to remove SlimeVR Driver."
    ${EndIf}
    Delete "$INSTDIR\steamvr.ps1"
SectionEnd

Section "-un.SlimeVR Feeder App" un.SEC_FEEDER_APP
    IfFileExists "$INSTDIR\Feeder-App\SlimeVR-Feeder-App.exe" found not_found
    found:
        DetailPrint "Unregistering SlimeVR Feeder App driver..."
        nsExec::ExecToLog '"$INSTDIR\Feeder-App\SlimeVR-Feeder-App.exe" --uninstall'
        DetailPrint "Removing SlimeVR Feeder App..."
        RMdir /r "$INSTDIR\Feeder-App"
    not_found:
SectionEnd

Section "-un." un.SEC_FIREWALL
    DetailPrint "Removing SlimeVR Server from firewall exceptions...."
    nsExec::Exec '"$INSTDIR\firewall_uninstall.bat"'
    Pop $0
    Delete "$INSTDIR\firewall*.bat"
SectionEnd

Section "-un." un.SEC_POST_UNINSTALL
    DetailPrint "Unregistering installation..."
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR"
    Delete "$INSTDIR\uninstall.exe"
    RMDir $INSTDIR
    DetailPrint "Done."
SectionEnd

LangString DESC_SEC_SERVER_GUI ${LANG_ENGLISH} "Installs latest SlimeVR Gui."
LangString DESC_SEC_SERVER ${LANG_ENGLISH} "Installs latest SlimeVR Server. Additionally downloads Java JRE 11."
LangString DESC_SEC_VRDRIVER ${LANG_ENGLISH} "Installs latest SlimeVR Driver in SteamVR."
LangString DESC_SEC_USBDRIVERS ${LANG_ENGLISH} "A list of USB drivers that are used by various boards."
LangString DESC_SEC_FEEDER_APP ${LANG_ENGLISH} "Installs SlimeVR Feeder App that sends position of SteamVR trackers (Vive trackers, controllers) to SlimeVR Server. Required for elbow tracking."
LangString DESC_SEC_CP210X ${LANG_ENGLISH} "Installs CP210X USB driver that comes with the following boards: NodeMCU v2, Wemos D1 Mini."
LangString DESC_SEC_CH340 ${LANG_ENGLISH} "Installs CH340 USB driver that comes with the following boards: NodeMCU v3, SlimeVR, Wemos D1 Mini."
LangString DESC_SEC_CH9102x ${LANG_ENGLISH} "Installs CH9102x USB driver that comes with the following boards: NodeMCU v2.1."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_SERVER_GUI} $(DESC_SEC_SERVER_GUI)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_SERVER} $(DESC_SEC_SERVER)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_VRDRIVER} $(DESC_SEC_VRDRIVER)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_USBDRIVERS} $(DESC_SEC_USBDRIVERS)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CP210X} $(DESC_SEC_CP210X)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CH340} $(DESC_SEC_CH340)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CH9102x} $(DESC_SEC_CH9102x)
!insertmacro MUI_FUNCTION_DESCRIPTION_END