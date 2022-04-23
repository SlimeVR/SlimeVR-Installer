@echo off
setlocal enableextensions
cd /d "%~dp0"
start slimevr-ui.exe
jre\bin\java.exe -Xmx512M -jar slimevr.jar
if %errorlevel% NEQ 0 (
    pause
)