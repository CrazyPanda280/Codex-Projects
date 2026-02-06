@echo off
setlocal
set SCRIPT=%~dp0PasswordFinder.ps1
if not exist "%SCRIPT%" (
  echo Datei nicht gefunden: %SCRIPT%
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
