; Macro: dlFiles
; Downloads a file from a specified URL, saves it locally, and unzips it to a target directory.
; Parameters:
;   name       - Display name of the file (for user messages)
;   version    - Version string (for user messages)
;   url        - URL to download the file from
;   local_file - Name to save the downloaded file as (in temp directory)
;   local_dir  - Directory to unzip the file into (relative to temp directory)
# 
!macro dlFiles name version url local_file local_dir

    DetailPrint "Downloading ${name} ${version}..."
    NScurl::http GET "${url}" "${SLIMETEMP}\${local_file}" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "Failed to download ${name} ${version}. Reason: $0."
    ${EndIf}
    DetailPrint "Downloaded!"

    DetailPrint "Unzipping ${name} ${version} to installation folder...."
    nsisunz::Unzip "${SLIMETEMP}\${local_file}" "${SLIMETEMP}\${local_dir}\"
    Pop $0
    DetailPrint "Unzipping finished with $0."

!macroend