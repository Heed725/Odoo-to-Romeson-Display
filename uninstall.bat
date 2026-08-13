@echo off
setlocal
call "%LOCALAPPDATA%\RomesonOdooBridge\stop-bridge.bat" 2>nul
del /Q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Romeson Odoo LED8 Bridge.lnk" 2>nul
netsh http delete urlacl url=http://127.0.0.1:8765/ >nul 2>&1
echo Remove the Edge extension from edge://extensions if it is still installed.
echo Installed files remain at %LOCALAPPDATA%\RomesonOdooBridge so they can be recovered.
echo You may delete that folder manually after closing this window.
pause
