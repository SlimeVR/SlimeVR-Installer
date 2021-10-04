Unicode True

!include x64.nsh 		; For RunningX64 check
!include LogicLib.nsh	; For conditional operators

# Define name of installer
Name "CP210x and CH340 Driver Installer"

SetOverwrite on
SetCompressor lzma  # Use LZMA Compression algorithm, compression quality is better.

OutFile "usb_drivers_installer.exe"

# Define installation directory
InstallDir "$TEMP\slimevr_usb_drivers_inst" ; $InstDir default value. Defaults to user's local appdata to avoid asking admin rights

# Admin rights are required for driver installation
RequestExecutionLevel admin

Page InstFiles

# Clean up on exit
Function .onGUIEnd
    RMDir /r $INSTDIR
FunctionEnd

# InstFiles section start
Section
    SetSilent silent
    SetAutoClose true

    # CP210X drivers (NodeMCU v2)
    SetOutPath "$INSTDIR\CP201x"
    DetailPrint "Installing CP210x driver..."
    File /r "CP201x\*"
    ${DisableX64FSRedirection}
    nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "$INSTDIR\CP201x\silabser.inf"' $0
    Pop $0
    ${EnableX64FSRedirection}
    ${If} $0 != 0
        SetErrorLevel 1
        Abort "Failed to install CP210x driver."
    ${Endif}

    # CH340 drivers (NodeMCU v3)
    SetOutPath "$INSTDIR\CH341SER"
    DetailPrint "Installing CH340 driver..."
    File /r "CH341SER\*"
    ${DisableX64FSRedirection}
    nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "$INSTDIR\CH341SER\CH341SER.INF"' $0
    Pop $0
    ${EnableX64FSRedirection}
    ${If} $0 != 0
        SetErrorLevel 1
        Abort "Failed to install CH340 driver."
    ${Endif}

    DetailPrint "Done."
SectionEnd
# InstFiles section end