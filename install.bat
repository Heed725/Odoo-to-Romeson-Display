@echo off
setlocal
set "INSTALL_DIR=%LOCALAPPDATA%\RomesonOdooBridge"

echo Installing Romeson Odoo LED8 Bridge...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
xcopy "%~dp0bridge" "%INSTALL_DIR%\bridge\" /E /I /Y >nul
xcopy "%~dp0extension" "%INSTALL_DIR%\extension\" /E /I /Y >nul
xcopy "%~dp0extension-firefox" "%INSTALL_DIR%\extension-firefox\" /E /I /Y >nul
copy /Y "%~dp0start-bridge.bat" "%INSTALL_DIR%\start-bridge.bat" >nul
copy /Y "%~dp0stop-bridge.bat" "%INSTALL_DIR%\stop-bridge.bat" >nul

netsh http delete urlacl url=http://127.0.0.1:8765/ >nul 2>&1
netsh http add urlacl url=http://127.0.0.1:8765/ user="%USERDOMAIN%\%USERNAME%" >nul
if errorlevel 1 (
    echo ERROR: Could not reserve the local bridge address.
    echo Right-click install.bat and choose Run as administrator.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut([Environment]::GetFolderPath('Startup')+'\Romeson Odoo LED8 Bridge.lnk'); $s.TargetPath='powershell.exe'; $s.Arguments='-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""%INSTALL_DIR%\bridge\romeson-bridge.ps1""'; $s.WorkingDirectory='%INSTALL_DIR%'; $s.Save()"

start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%INSTALL_DIR%\bridge\romeson-bridge.ps1"

echo.
echo Installation complete.
echo.
echo Edge:
echo   Open edge://extensions, enable Developer mode, click Load unpacked,
echo   and select: %INSTALL_DIR%\extension
echo.
echo Chrome:
echo   Open chrome://extensions, enable Developer mode, click Load unpacked,
echo   and select: %INSTALL_DIR%\extension
echo.
echo Firefox:
echo   Open about:debugging#/runtime/this-firefox, click Load Temporary Add-on,
echo   and select: %INSTALL_DIR%\extension-firefox\manifest.json
echo.
echo Restart the Odoo POS page after loading the extension.
echo The bridge starts automatically when this Windows user signs in.
pause
