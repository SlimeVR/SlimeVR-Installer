# check if one of the Processes is running to warn the user.
# vrwebhelper.exe
# vrserver.exe
# vrmonitor.exe
# vrdashboard.exe
# vrcompositor.exe
!macro ProcessCheck un GLOBVARRETURN

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
    ; Test if SlimeVR is Running
    StrCpy $${GLOBVARRETURN} "NotFound" 
    Push "slimevr.exe"
    Call ${un}TestProcess
    StrCpy $SlimeVRRunning $${GLOBVARRETURN}
    ; Test if SteamVR is Running
    Call ${un}SteamVRTest

    ; Set the Warning lable for SteamVR
    ${If} $${GLOBVARRETURN} == "Found"
        StrCpy $SteamVRLabelTxt $(DESC_STEAMVR_RUNNING)
    ${ElseIf} $${GLOBVARRETURN} == "NotFound"
        StrCpy $SteamVRLabelTxt ""
    ${EndIf}

    ; Set the Warning lable for SlimeVR
    ${If} $SlimeVRRunning == "Found"
        StrCpy $SlimeVRLabelTxt $(DESC_SLIMEVR_RUNNING)
    ${ElseIf} $SlimeVRRunning == "NotFound"
        StrCpy $SlimeVRLabelTxt ""
    ${EndIf}

    ; Logic for Enable Disable the Buttons
    ${If} $${GLOBVARRETURN} == "Found"
    ${OrIf} $SlimeVRRunning == "Found"
        Call ${un}NextButtonDisable
    ${ElseIf} $${GLOBVARRETURN} == "NotFound"
    ${AndIf} $SlimeVRRunning == "NotFound"
        Call ${un}NextButtonEnable
    ${EndIf}
#    MessageBox MB_OK "SteamVRTest Result $SteamVRLabelTxt"
    ${NSD_SetText} $SteamVRLabelID $SteamVRLabelTxt
    ${NSD_SetText} $SlimeVRLabelID $SlimeVRLabelTxt
FunctionEnd

!macroend

