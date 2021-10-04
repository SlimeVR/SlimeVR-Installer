# SlimeVR web installer

An NSIS-based web installer for SlimeVR components. It includes:

* Downloading and unpacking SlimeVR Server into installation directory.
* Download SlimeVR Driver and copy/remove it to/from SteamVR (requires Powershell).
* Downloading JRE 11 from [Adoptium project](https://adoptium.net/).
* Adding/removing firewall rules.
* Installing CH340/CH341 and CP210x drivers.

## Used plugins

The NSIS script is powered by the following plugins:

* [NScurl plug-in](https://nsis.sourceforge.io/NScurl_plug-in) - for downloads over HTTP.
* [Nsisunz plug-in](https://nsis.sourceforge.io/Nsisunz_plug-in) - for zip archives unpacking.

## Building

1. Download and install the latest [NSIS package](https://nsis.sourceforge.io/Download).
1. Copy plugin DLLs to corresponding folders to `<NSIS_INSTDIR>\Plugins`.
1. Run NSIS and click **Compile NSI scripts**.
1. Open and build `slimevr_web_installer.nsi` by following the usage instructions in the opened **MakeNSISW** window.
1. Open and build `usb_drivers_installer.nsi` the same way as in previous step.

## Useful links

NSIS Scripting Reference - <https://nsis.sourceforge.io/Docs/Chapter4.html>
