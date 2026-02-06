@echo off
setlocal
set APP=%~dp0PasswordFinder.hta
if not exist "%APP%" (
  echo Datei nicht gefunden: %APP%
  pause
  exit /b 1
)
start "Password Finder" mshta.exe "%APP%"
