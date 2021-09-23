# SlimeVR web installer

An NSIS-based web installer for SlimeVR components. It includes:

* Downloading and unpacking SlimeVR Server and SlimeVR Driver into installation directory.
* Dynamic registration/unregistration of SlimeVR Driver in SteamVR.
* Downloading JRE 11 from [Adoptium project](https://adoptium.net/).

## Used plugins

The NSIS script is powered by the following plugins:

* [NScurl plug-in](https://nsis.sourceforge.io/NScurl_plug-in) - for downloads over HTTP.
* [Nsisunz plug-in](https://nsis.sourceforge.io/Nsisunz_plug-in) - for zip archives unpacking.

## Building

1. Download and install the latest [NSIS package](https://nsis.sourceforge.io/Download).
1. Copy plugin DLLs to corresponding folders to `<NSIS_INSTDIR>\Plugins`.
1. Run NSIS and click **Compile NSI scripts**.
1. Follow the usage instructions in the opened **MakeNSISW** window.

## Useful links

NSIS Scripting Reference - <https://nsis.sourceforge.io/Docs/Chapter4.html>
