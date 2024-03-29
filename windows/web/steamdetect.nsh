# check if one of the Processes is running to warn the user.
# vrwebhelper.exe
# vrserver.exe
# vrmonitor.exe
# vrdashboard.exe
# vrcompositor.exe
!macro SteamProcessCheck un GLOBVARRETURN

Function ${un}SteamVRTest
    StrCpy $${GLOBVARRETURN} "NotFound" 
    Push "vrwebhelper.exe"
    Call ${un}TestProcess
    Push "vrserver.exe"
    Call ${un}TestProcess
    Push "vrmonitor.exe"
    Call ${un}TestProcess
    Push "vrdashboard.exe"
    Call ${un}TestProcess
    Push "vrcompositor.exe"
    Call ${un}TestProcess
#    MessageBox MB_OK "SteamVRTest Result $${GLOBVARRETURN}"
FunctionEnd

Function ${un}TestProcess
    Pop $0 
    ${nsProcess::FindProcess} $0 $TestProcessReturn
#    MessageBox MB_OK "TestProcess $0 Result $TestProcessReturn"
    ${if} $TestProcessReturn = 0
        StrCpy $${GLOBVARRETURN} "Found"
    ${elseif} $TestProcessReturn != 603
        MessageBox MB_OK "$(DESC_PROCESS_ERROR) $TestProcessReturn"
        # An error happend while trying for look for $0 nsProcess::FindProcess Returns $TestProcessReturn
        StrCpy $${GLOBVARRETURN} "Error"
    ${EndIf}
FunctionEnd

Function ${un}NextButtonDisable
    GetDlgItem $0 $hwndparent 1 ; 1 is the ID of the Next button
    EnableWindow $0 0
FunctionEnd

Function ${un}NextButtonEnable
    GetDlgItem $0 $hwndparent 1 ; 1 is the ID of the Next button
    EnableWindow $0 1
FunctionEnd


Function ${un}UpdateLabelTimer
    Call ${un}SteamVRTest
    ${if} $${GLOBVARRETURN} == "Found"
        Call ${un}NextButtonDisable
        StrCpy $SteamVRLabelTxt $(DESC_STEAMVR_RUNNING)
    ${elseif} $${GLOBVARRETURN} == "NotFound"
        Call ${un}NextButtonEnable
        StrCpy $SteamVRLabelTxt ""
    ${endif}
#    MessageBox MB_OK "SteamVRTest Result $SteamVRLabelTxt"
    ${NSD_SetText} $SteamVRLabelID $SteamVRLabelTxt
FunctionEnd

!macroend

