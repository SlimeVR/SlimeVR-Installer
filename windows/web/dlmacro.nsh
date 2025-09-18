; Macro: dlFile
; Downloads a file from a URL or extracts a local file to ${SLIMETEMP}, based on source_type.
; Parameters:
;   source_type - "url" to download, "local" to extract from local file (embedded in installer)
;   name        - Display name of the file (for user messages)
;   version     - Version string (for user messages)
;   url_or_path - URL to download from (if source_type is "url"), or local file path (if "local")
;   local_file  - File name to save as in ${SLIMETEMP} (e.g., "archive.zip")
; Notes:
;   - If source_type is "url", uses NScurl::http with /CANCEL and /RESUME; pops status text into $0 ("OK" on success)
;   - If source_type is "local", embeds the file at compile time and extracts it to ${SLIMETEMP} at install time
;   - Call unzipFile separately to extract the downloaded or copied archive
; Example:
;   !insertmacro dlFile "url" "Java JRE" "17.0.15+6" "https://example.com/jre.zip" "jre.zip"
;   !insertmacro dlFile "local" "Java JRE" "17.0.15+6" "assets\\jre.zip" "jre.zip"
!macro dlFile source_type name version url_or_path local_file
    !if "${source_type}" == "url"
        DetailPrint "Downloading ${name} ${version}..."
        NScurl::http GET "${url_or_path}" "${SLIMETEMP}\${local_file}" /CANCEL /RESUME /END
        Pop $0 ; Status text ("OK" for success)
        ${If} $0 != "OK"
            Abort "Failed to download ${name} ${version}. Reason: $0."
        ${EndIf}
        DetailPrint "Downloaded!"
    !else
        !if "${source_type}" == "local"
            DetailPrint "Using bundled ${name} ${version}..."
            Push $0
            StrCpy $0 $OUTDIR
            CreateDirectory "${SLIMETEMP}"
            SetOutPath "${SLIMETEMP}"
            File "/oname=${local_file}" "${url_or_path}"
            SetOutPath $0
            Pop $0
            IfFileExists "${SLIMETEMP}\${local_file}" +2 0
                Abort "Failed to place bundled ${name} ${version} at ${SLIMETEMP}\\${local_file}."
            DetailPrint "Bundled file ready: ${SLIMETEMP}\\${local_file}"
        !else
            Abort "dlFile: Unknown source_type '${source_type}'. Use 'url' or 'local'."
        !endif
    !endif
!macroend



; Macro: unzipFile
; Extracts a ZIP archive from the temporary installer directory into a target subdirectory.
; Parameters:
;   name       - Friendly display name shown in the log (e.g., "Java JRE")
;   version    - Version label shown in the log (e.g., "17.0.15+6" or "latest")
;   local_file - ZIP file name located under ${SLIMETEMP} (e.g., "archive.zip")
;   local_dir  - Destination directory name to extract into
;                (e.g., "${SLIMETEMP}\OpenJDK\" -> extracts to "${SLIMETEMP}\OpenJDK\...")
; Behavior:
;   - Logs start/end messages with DetailPrint
;   - Calls Nsisunz plugin to unzip: nsisunz::Unzip "${local_file}" "${local_dir}"
;   - Pops plugin return value into $0 (status depends on plugin build)
; Requirements:
;   - ${SLIMETEMP} must be defined and writable
;   - Nsisunz plugin must be available via !AddPluginDir
; Notes:
;   - This macro does not validate the unzip result; add checks after calling if needed.
; Example:
;   !insertmacro unzipFile "Java JRE" "${JREVersion}" "${JREDownloadedFileZip}" "OpenJDK"
!macro unzipFile name version local_file local_dir

    DetailPrint "Unzipping ${name} ${version} to installation folder...."
    nsisunz::Unzip "${SLIMETEMP}\${local_file}" "${local_dir}"
    Pop $0
    DetailPrint "Unzipping finished with $0."

!macroend