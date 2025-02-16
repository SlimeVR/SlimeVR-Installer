Unicode True

!include x64.nsh 		; For RunningX64 check
!include LogicLib.nsh	; For conditional operators
!include nsDialogs.nsh  ; For custom pages
!include FileFunc.nsh   ; For GetTime function
!include .\plugins\NsProcess\NsProcess.nsh ; For Check on SteamVR
#!include WinMessages.nsh
!include TextFunc.nsh   ; For ConfigRead
!include MUI2.nsh
!include .\steamdetect.nsh

!define SF_USELECTED  0
!define MUI_ICON "run.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "logo.bmp"
!define MUI_HEADERIMAGE_BITMAP_STRETCH "NoStretchNoCrop"
!define MUI_HEADERIMAGE_RIGHT
!define SLIMETEMP "$TEMP\SlimeVRInstaller"

# Define the Java Version Strings and to Check (JRE\relase -> JAVA_RUNTIME_VERSION=)
!define JREVersion "17.0.14+7"
!define JREDownloadURL "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.14%2B7/OpenJDK17U-jre_x64_windows_hotspot_17.0.14_7.zip"
!define JREDownloadedFileZip "OpenJDK17U-jre_x64_windows_hotspot_17.0.14_7.zip"
Var JREneedInstall

Var /GLOBAL SteamVRResult
Var /GLOBAL SteamVRLabelID
Var /GLOBAL SteamVRLabelTxt
Var /GLOBAL TestProcessReturn
Var /GLOBAL SlimeVRRunning
Var /GLOBAL SlimeVRLabelID
Var /GLOBAL SlimeVRLabelTxt

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

BrandingText "SlimeVR Installer 0.2.0"

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

# Init functions start #
Function .onInit
    InitPluginsDir
    ${If} ${RunningX64}
        ReadRegStr $0 HKLM SOFTWARE\WOW6432Node\Valve\Steam InstallPath
    ${Else}
        ReadRegStr $0 HKLM SOFTWARE\Valve\Steam InstallPath
    ${EndIf}
    StrCpy $STEAMDIR $0
FunctionEnd

!insertmacro ProcessCheck "un." "SteamVRResult"
!insertmacro ProcessCheck "" "SteamVRResult"

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
    RMDir /r "${SLIMETEMP}"
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
    Delete "$INSTDIR\slimevr*"
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

    RMDir $INSTDIR
FunctionEnd
# Init functions end #

Page Custom startPage startPageLeave

!define MUI_PAGE_CUSTOMFUNCTION_PRE componentsPre
# !define MUI_PAGE_CUSTOMFUNCTION_SHOW componentsShow
!insertmacro MUI_PAGE_COMPONENTS

!define MUI_PAGE_CUSTOMFUNCTION_PRE installerActionPre
!insertmacro MUI_PAGE_DIRECTORY

!define MUI_PAGE_CUSTOMFUNCTION_PRE cleanTemp ; Clean temp on pre-install to avoid any leftover files failing the installation, temp files will be removed in .onGUIEnd
!insertmacro MUI_PAGE_INSTFILES

Page Custom endPage endPageLeave


# Set MUI_UNCONFIMPAGE to get the translations
!insertmacro MUI_SET MUI_UNCONFIRMPAGE ""
UninstPage custom un.startPageConfirm un.endPageunConfirm
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

LangString START_PAGE_TITLE ${LANG_ENGLISH} "Welcome"
LangString START_PAGE_SUBTITLE ${LANG_ENGLISH} "Welcome to SlimeVR Setup!"

Function startPage
    Call UpdateLabelTimer
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

    ${NSD_CreateLabel} 0 90u 100% 10u '$SteamVRLabelTxt'
    Pop $SteamVRLabelID
    ${NSD_CreateLabel} 0 100u 100% 10u '$SlimeVRLabelTxt'
    Pop $SlimeVRLabelID
    GetFunctionAddress $0 UpdateLabelTimer
    nsDialogs::CreateTimer $0 2000 ; Set the timer interval to 1000 milliseconds (1 second)

    nsDialogs::Show

FunctionEnd

Function startPageLeave
    GetFunctionAddress $0 UpdateLabelTimer
    nsDialogs::KillTimer $0
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
    # Don't open documentation if we're updating
    ${If} $SELECTED_INSTALLER_ACTION == ""
        ${NSD_Check} $OPEN_DOCUMENTATION
    ${EndIf}

    ${NSD_CreateCheckbox} 0 40u 100% 10u "Create Desktop shortcut"
    Pop $CREATE_DESKTOP_SHORTCUT
    ${NSD_Check} $CREATE_DESKTOP_SHORTCUT
    ${NSD_CreateCheckbox} 0 55u 100% 10u "Create Start Menu shortcuts"
    Pop $CREATE_STARTMENU_SHORTCUTS
    ${NSD_Check} $CREATE_STARTMENU_SHORTCUTS

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
        CreateShortcut "$SMPROGRAMS\SlimeVR Server\SlimeVR Server.lnk" "$INSTDIR\slimevr.exe" ""
    ${Else}
        Delete "$SMPROGRAMS\Uninstall SlimeVR Server.lnk"
        Delete "$SMPROGRAMS\SlimeVR Server.lnk"
        RMdir /r "$SMPROGRAMS\SlimeVR Server"
    ${Endif}

    ${If} $1 = 1
        CreateShortcut "$DESKTOP\SlimeVR Server.lnk" "$INSTDIR\slimevr.exe" ""
    ${Else}
        Delete "$DESKTOP\SlimeVR Server.lnk"
    ${EndIf}
    
    ${If} $2 = 1
        ExecShell "open" "https://docs.slimevr.dev/server-setup/slimevr-setup.html"
    ${EndIf}

FunctionEnd

# Pre-hook for directory selection function
Function installerActionPre
    # Skip directory selection if existing installation was detected and user selected an action
    ${If} $SELECTED_INSTALLER_ACTION != ""
        Abort
    ${EndIf}
FunctionEnd

# Provides a easy function to determit if the JRE is the desired Version or not
Function JREdetect
    IfFileExists "$INSTDIR\jre\release" 0 SEC_JRE_JAVAVERSIONELSE
        ${ConfigRead} "$INSTDIR\jre\release" "JAVA_RUNTIME_VERSION=" $R0
;        DetailPrint "Java JRE: $INSTDIR\jre\release JAVA_RUNTIME_VERSION=$R0"
        ${If} $R0 == "$\"${JREVersion}$\""
            StrCpy $JREneedInstall "False"
        ${Else}
            StrCpy $JREneedInstall "True"
        ${EndIf}
        Goto SEC_JRE_JAVAVERSIONDONE
    SEC_JRE_JAVAVERSIONELSE:
        StrCpy $JREneedInstall "True"
;        DetailPrint "Java JRE: $INSTDIR\jre\release File Not Found"
    SEC_JRE_JAVAVERSIONDONE:
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

# Uninstall Confirm Page Clone to add some Labels
Function un.startPageConfirm
    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
      Abort
    ${EndIf}
    
    !insertmacro MUI_HEADER_TEXT $(MUI_UNTEXT_CONFIRM_TITLE) $(MUI_UNTEXT_CONFIRM_SUBTITLE)

    ; Uninstalling Text 
    ${NSD_CreateLabel} 0 0 450 30 "$(^UninstallingText)"

    ; Uninstalling Path Text
    ${NSD_CreateLabel} 0 68 98 20 "$(^UninstallingSubText)"

    ; Uninstalling Path
    ${NSD_CreateText} 98 65 350 20 "$INSTDIR"
    Pop $0
    SendMessage $0 ${EM_SETREADONLY} 1 0

    ; Create the SteamVR Warning Label
    ${NSD_CreateLabel} 0 90u 100% 10u '$SteamVRLabelTxt'
    Pop $SteamVRLabelID
    ${NSD_CreateLabel} 0 100u 100% 10u '$SlimeVRLabelTxt'
    Pop $SlimeVRLabelID

    Call un.UpdateLabelTimer
    GetFunctionAddress $0 un.UpdateLabelTimer
    nsDialogs::CreateTimer /NOUNLOAD $0 2000 ; Set the timer interval to 2000 milliseconds (2 second)

    nsDialogs::Show
FunctionEnd

Function un.endPageunConfirm
    GetFunctionAddress $0 un.UpdateLabelTimer
    nsDialogs::KillTimer $0
FunctionEnd

Section "SlimeVR Server" SEC_SERVER
    SectionIn RO

    SetOutPath $INSTDIR

    DetailPrint "Downloading SlimeVR Server..."
    NScurl::http GET "https://github.com/SlimeVR/SlimeVR-Server/releases/latest/download/SlimeVR-win64.zip" "${SLIMETEMP}\SlimeVR-win64.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download SlimeVR Server. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    nsisunz::Unzip "${SLIMETEMP}\SlimeVR-win64.zip" "${SLIMETEMP}\SlimeVR\"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    ${If} $SELECTED_INSTALLER_ACTION == "update"
        Delete "$INSTDIR\slimevr-ui.exe"
    ${EndIf}

    DetailPrint "Copying SlimeVR Server to installation folder..."
    CopyFiles /SILENT "${SLIMETEMP}\SlimeVR\SlimeVR\*" $INSTDIR

    IfFileExists "$INSTDIR\slimevr-ui.exe" found not_found
    found:
        Delete "$INSTDIR\slimevr.exe"
        Rename "$INSTDIR\slimevr-ui.exe" "$INSTDIR\slimevr.exe"
    not_found:

    Delete "$INSTDIR\run.bat"
    Delete "$INSTDIR\run.ico"
    
    # Create the uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Webview2" SEC_WEBVIEW
    SectionIn RO

    # Read Only protects it from Installing when it is not needed
    DetailPrint "Downloading webview2!"
    NScurl::http GET "https://go.microsoft.com/fwlink/p/?LinkId=2124703" "${SLIMETEMP}\MicrosoftEdgeWebView2RuntimeInstaller.exe" /CANCEL /RESUME /END

    DetailPrint "Installing webview2!"
    nsExec::ExecToLog '"${SLIMETEMP}\MicrosoftEdgeWebView2RuntimeInstaller.exe" /silent /install' $0
    Pop $0
    DetailPrint "Installing finished with $0."
    ${If} $0 != 0
        Abort "Failed to install webview 2"
    ${EndIf}

SectionEnd

Section "Java JRE" SEC_JRE
    SectionIn RO
    
    DetailPrint "Downloading Java JRE ${JREVersion}..."
    NScurl::http GET "${JREDownloadURL}" "${SLIMETEMP}\${JREDownloadedFileZip}" /CANCEL /RESUME /END
    
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download Java JRE ${JREVersion}. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    # Make sure to delete all files on a update from jre, so if there is a new version no old files are left.
    IfFileExists "$INSTDIR\jre" 0 SEC_JRE_DIRNOTFOUND
        DetailPrint "Removing old Java JRE..."
        RMdir /r "$INSTDIR\jre"
        CreateDirectory "$INSTDIR\jre"
    SEC_JRE_DIRNOTFOUND:

    DetailPrint "Unzipping Java JRE ${JREVersion} to installation folder...."
    nsisunz::Unzip "${SLIMETEMP}\${JREDownloadedFileZip}" "${SLIMETEMP}\OpenJDK\"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    FindFirst $0 $1 "${SLIMETEMP}\OpenJDK\jdk-17.*-jre"
    loop:
        StrCmp $1 "" done
        CopyFiles /SILENT "${SLIMETEMP}\OpenJDK\$1\*" "$INSTDIR\jre"
        FindNext $0 $1
        Goto loop
    done:
    FindClose $0
SectionEnd

Section "SteamVR Driver" SEC_VRDRIVER
    SetOutPath $INSTDIR

    DetailPrint "Downloading SteamVR Driver..."
    NScurl::http GET "https://github.com/SlimeVR/SlimeVR-OpenVR-Driver/releases/latest/download/slimevr-openvr-driver-win64.zip" "${SLIMETEMP}\slimevr-openvr-driver-win64.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download SteamVR Driver. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    DetailPrint "Unpacking downloaded files..."
    nsisunz::Unzip "${SLIMETEMP}\slimevr-openvr-driver-win64.zip" "${SLIMETEMP}\slimevr-openvr-driver-win64\"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    # Include SteamVR powershell script to register/unregister driver
    File "steamvr.ps1"

    DetailPrint "Copying SteamVR Driver to SteamVR..."
    # If powershell is present - rely on automatic detection.
    ${DisableX64FSRedirection}
    nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$STEAMDIR" -DriverPath "${SLIMETEMP}\slimevr-openvr-driver-win64\slimevr"' $0
    ${EnableX64FSRedirection}
    Pop $0
    ${If} $0 != 0
        nsDialogs::SelectFolderDialog "Specify a path to your SteamVR folder" "$STEAMDIR\steamapps\common\SteamVR"
        Pop $0
        ${If} $0 == "error"
            Abort "Failed to copy SlimeVR Driver."
        ${Endif}
        CopyFiles /SILENT "${SLIMETEMP}\slimevr-openvr-driver-win64\slimevr" "$0\drivers\slimevr"
    ${EndIf}
SectionEnd

Section "SlimeVR Feeder App" SEC_FEEDER_APP
    SetOutPath $INSTDIR

    DetailPrint "Downloading SlimeVR Feeder App..."
    NScurl::http GET "https://github.com/SlimeVR/SlimeVR-Feeder-App/releases/latest/download/SlimeVR-Feeder-App-win64.zip" "${SLIMETEMP}\SlimeVR-Feeder-App-win64.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download SlimeVR Feeder App. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    DetailPrint "Unpacking downloaded files..."
    nsisunz::Unzip "${SLIMETEMP}\SlimeVR-Feeder-App-win64.zip" "${SLIMETEMP}"
    Pop $0
    DetailPrint "Unzipping finished with $0."

    DetailPrint "Copying SlimeVR Feeder App..."
    CopyFiles /SILENT "${SLIMETEMP}\SlimeVR-Feeder-App-win64\*" "$INSTDIR\Feeder-App"

    DetailPrint "Installing SlimeVR Feeder App driver..."
    nsExec::ExecToLog '"$INSTDIR\Feeder-App\SlimeVR-Feeder-App.exe" --install'
SectionEnd

Section "Microsoft Visual C++ Redistributable" SEC_MSVCPP
    SetOutPath $INSTDIR
    DetailPrint "Downloading Microsoft Visual C++ Redistributable..."
    NScurl::http GET "https://aka.ms/vs/17/release/vc_redist.x64.exe" "${SLIMETEMP}\vc_redist.x64.exe" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download Microsoft Visual C++ Redistributable. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"
    DetailPrint "Installing Microsoft Visual C++ Redistributable..."
    nsExec::ExecToLog '"${SLIMETEMP}\vc_redist.x64.exe" /install /passive /norestart' $0
    Pop $0 ; Status text ("OK" for success)
    ; Handle return codes
    ${If} $0 == 0
        DetailPrint "Microsoft Visual C++ Redistributable installed successfully."
    ${ElseIf} $0 == 3010
        DetailPrint "Microsoft Visual C++ Redistributable installed successfully, but a reboot is required."
        SetRebootFlag true
    ${ElseIf} $0 == 1602
        Abort "User canceled the Microsoft Visual C++ Redistributable installation."
    ${ElseIf} $0 == 1603
        Abort "Fatal error during Microsoft Visual C++ Redistributable installation."
    ${ElseIf} $0 == 1618
        Abort "Installation aborted: Another installation is in progress."
    ${ElseIf} $0 == 1638
        DetailPrint "Microsoft Visual C++ Redistributable is already installed or a newer version is present."
    ${ElseIf} $0 == 1641
        DetailPrint "Microsoft Visual C++ Redistributable installed successfully, and a system restart is happening."
    ${ElseIf} $0 == 5100
        Abort "Installation failed: Unsupported operating system."
    ${Else}
        Abort "Microsoft Visual C++ Redistributable installation failed with unknown error code: $0"
    ${EndIf}
SectionEnd

SectionGroup /e "USB drivers" SEC_USBDRIVERS

    Section "CP210x driver" SEC_CP210X
        # CP210X drivers (NodeMCU v2)
        SetOutPath "${SLIMETEMP}\slimevr_usb_drivers_inst\CP201x"
        DetailPrint "Installing CP210x driver..."
        File /r "CP201x\*"
        ${DisableX64FSRedirection}
        nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "${SLIMETEMP}\slimevr_usb_drivers_inst\CP201x\silabser.inf"' $0
        ${EnableX64FSRedirection}
        Pop $0
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
        SetOutPath "${SLIMETEMP}\slimevr_usb_drivers_inst\CH341SER"
        DetailPrint "Installing CH340 driver..."
        File /r "CH341SER\*"
        ${DisableX64FSRedirection}
        nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "${SLIMETEMP}\slimevr_usb_drivers_inst\CH341SER\CH341SER.INF"' $0
        ${EnableX64FSRedirection}
        Pop $0
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
        SetOutPath "${SLIMETEMP}\slimevr_usb_drivers_inst\CH343SER"
        DetailPrint "Installing CH910x driver..."
        File /r "CH343SER\*"
        ${DisableX64FSRedirection}
        nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "${SLIMETEMP}\slimevr_usb_drivers_inst\CH343SER\CH343SER.INF"' $0
        ${EnableX64FSRedirection}
        Pop $0
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
                    "DisplayIcon" "$INSTDIR\slimevr.exe"
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
    Call JREdetect
    ${If} $SELECTED_INSTALLER_ACTION == "update"
        SectionSetFlags ${SEC_FIREWALL} 0
        SectionSetFlags ${SEC_REGISTERAPP} 0
        SectionSetFlags ${SEC_WEBVIEW} ${SF_SELECTED}
        SectionSetFlags ${SEC_MSVCPP} ${SF_SELECTED}
        SectionSetFlags ${SEC_USBDRIVERS} ${SF_SECGRP}
        SectionSetFlags ${SEC_SERVER} ${SF_SELECTED}
    ${EndIf}
    ${If} $STEAMDIR == ""
        MessageBox MB_OK $(DESC_STEAM_NOTFOUND)
        SectionSetFlags ${SEC_VRDRIVER} ${SF_USELECTED}|${SF_RO}
        SectionSetFlags ${SEC_FEEDER_APP} ${SF_USELECTED}|${SF_RO}
        SectionSetFlags ${SEC_MSVCPP} ${SF_USELECTED}|${SF_RO}
    ${Else}
        SectionSetFlags ${SEC_VRDRIVER} ${SF_SELECTED}
        SectionSetFlags ${SEC_FEEDER_APP} ${SF_SELECTED}
        SectionSetFlags ${SEC_MSVCPP} ${SF_SELECTED}|${SF_RO}
    ${EndIf}

    # Select JRE Mandatory if not found or outdated on Repair Preselect it
    ${If} $JREneedInstall == "True"
        SectionSetFlags ${SEC_JRE} ${SF_SELECTED}|${SF_RO}
    ${ElseIf} $SELECTED_INSTALLER_ACTION == "repair"
        SectionSetFlags ${SEC_JRE} ${SF_SELECTED}
    ${Else}        
        SectionSetFlags ${SEC_JRE} ${SF_USELECTED}
    ${EndIf}

    # Detect WebView2
    # https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution#detect-if-a-suitable-webview2-runtime-is-already-installed
    # Trying to solve #41 Installer doesn't always install WebView2
    # Ignoring only user installed WebView2 it seems to make problems
    ${If} ${RunningX64}
        ReadRegStr $0 HKLM "SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
        ReadRegStr $1 HKCU "Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
    ${Else}
        ReadRegStr $0 HKLM "SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
        ReadRegStr $1 HKCU "Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
    ${EndIf}

    ${If} $0 == ""
    ${OrIf} $0 == "0.0.0.0"
        StrCpy $0 ""
    ${Else}
        StrCpy $0 "1"
    ${EndIf}

    ${If} $1 == ""
    ${OrIf} $1 == "0.0.0.0"
        StrCpy $1 ""
    ${Else}
        StrCpy $1 "1"
    ${EndIf}

    ${If} $0 == ""
    ${AndIf} $1 == ""
        SectionSetFlags ${SEC_WEBVIEW} ${SF_SELECTED}|${SF_RO}
    ${Else}
        SectionSetFlags ${SEC_WEBVIEW} ${SF_USELECTED}
    ${EndIf}
FunctionEnd

Function .onSelChange
    SectionGetFlags ${SEC_VRDRIVER} $0
    IntOp $0 $0 & ${SF_SELECTED}
    SectionGetFlags ${SEC_FEEDER_APP} $1
    IntOp $1 $1 & ${SF_SELECTED}
    IntOp $0 $0 | $1
    ${If} $0 == ${SF_SELECTED}
        SectionSetFlags ${SEC_MSVCPP} ${SF_SELECTED}|${SF_RO}
    ${Else}
        SectionSetFlags ${SEC_MSVCPP} ${SF_USELECTED}|${SF_RO}
    ${EndIf}
FunctionEnd

Section "-un.SlimeVR Server" un.SEC_SERVER
    # Remove the shortcuts
    RMdir /r "$SMPROGRAMS\SlimeVR Server"
    # Remove separate shortcuts introduced with first release
    Delete "$SMPROGRAMS\Uninstall SlimeVR Server.lnk"
    Delete "$SMPROGRAMS\SlimeVR Server.lnk"
    Delete "$DESKTOP\SlimeVR Server.lnk"
    Delete "$INSTDIR\slimevr-ui.exe"
    Delete "$INSTDIR\run.bat"
    Delete "$INSTDIR\run.ico"
    # Ignore errors on the files above, they are optional to remove and may not even exist
    ClearErrors
    Delete "$INSTDIR\slimevr*"
    Delete "$INSTDIR\MagnetoLib.dll"
    Delete "$INSTDIR\log*"
    Delete "$INSTDIR\*.log"
    Delete "$INSTDIR\*.lck"
    Delete "$INSTDIR\vrconfig.yml"
    Delete "$INSTDIR\LICENSE*"
    Delete "$INSTDIR\ThirdPartyNotices.txt"

    RMDir /r "$INSTDIR\Recordings"
    RMdir /r "$INSTDIR\jre"
    RMDir /r "$INSTDIR\logs"

    IfErrors fail success
    fail:
        Abort "Failed to remove SlimeVR Server files. Make sure SlimeVR Server is closed."
    success:
SectionEnd

Section "-un.SteamVR Driver" un.SEC_VRDRIVER
    ${DisableX64FSRedirection}
    nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$STEAMDIR" -DriverPath "slimevr" -Uninstall' $0
    ${EnableX64FSRedirection}
    Pop $0
    ${If} $0 != 0
        DetailPrint "Failed to remove SteamVR Driver."
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

LangString DESC_SEC_SERVER ${LANG_ENGLISH} "Installs latest SlimeVR Server."
LangString DESC_SEC_JRE ${LANG_ENGLISH} "Downloads and copies Java JRE 17 to installation folder. Required for SlimeVR Server."
LangString DESC_SEC_WEBVIEW ${LANG_ENGLISH} "Downloads and install Webview2 if not already installed. Required for the SlimeVR GUI"
LangString DESC_SEC_VRDRIVER ${LANG_ENGLISH} "Installs latest SteamVR Driver for SlimeVR."
LangString DESC_SEC_USBDRIVERS ${LANG_ENGLISH} "A list of USB drivers that are used by various boards."
LangString DESC_SEC_FEEDER_APP ${LANG_ENGLISH} "Installs SlimeVR Feeder App that sends position of SteamVR trackers (Vive trackers, controllers) to SlimeVR Server. Required for elbow tracking."
LangString DESC_SEC_MSVCPP ${LANG_ENGLISH} "Installs the latest Microsoft Visual C++ Redistributable Version (required by the SteamVR Driver and the SlimeVR Feeder)"
LangString DESC_SEC_CP210X ${LANG_ENGLISH} "Installs CP210X USB driver that comes with the following boards: NodeMCU v2, Wemos D1 Mini."
LangString DESC_SEC_CH340 ${LANG_ENGLISH} "Installs CH340 USB driver that comes with the following boards: NodeMCU v3, SlimeVR, Wemos D1 Mini."
LangString DESC_SEC_CH9102x ${LANG_ENGLISH} "Installs CH9102x USB driver that comes with the following boards: NodeMCU v2.1."
LangString DESC_STEAM_NOTFOUND ${LANG_ENGLISH} "No Steam installation detected. Steam and SteamVR are required to be installed and run at least once to install the SteamVR Driver."
LangString DESC_STEAMVR_RUNNING ${LANG_ENGLISH} "SteamVR is running! Please close SteamVR."
LangString DESC_SLIMEVR_RUNNING ${LANG_ENGLISH} "SlimeVR is running! Please close SlimeVR."
LangString DESC_PROCESS_ERROR ${LANG_ENGLISH} "An error happend while trying for look for $0 nsProcess::FindProcess Returns "

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_SERVER} $(DESC_SEC_SERVER)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_JRE} $(DESC_SEC_JRE)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_WEBVIEW} $(DESC_SEC_WEBVIEW)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_VRDRIVER} $(DESC_SEC_VRDRIVER)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_FEEDER_APP} $(DESC_SEC_FEEDER_APP)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_MSVCPP} $(DESC_SEC_MSVCPP)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_USBDRIVERS} $(DESC_SEC_USBDRIVERS)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CP210X} $(DESC_SEC_CP210X)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CH340} $(DESC_SEC_CH340)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CH9102x} $(DESC_SEC_CH9102x)
!insertmacro MUI_FUNCTION_DESCRIPTION_END