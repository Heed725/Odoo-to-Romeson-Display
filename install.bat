@echo off
setlocal
set "INSTALL_DIR=%LOCALAPPDATA%\RomesonOdooBridge"

echo Installing Romeson Odoo LED8 Bridge...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
xcopy "%~dp0bridge" "%INSTALL_DIR%\bridge\" /E /I /Y >nul
xcopy "%~dp0extension" "%INSTALL_DIR%\extension\" /E /I /Y >nul
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
echo 1. Open Edge and enter: edge://extensions
echo 2. Turn on Developer mode.
echo 3. Click Load unpacked.
echo 4. Paste this folder path into the folder box:
echo    %INSTALL_DIR%\extension
echo 5. Select Folder, then restart Odoo POS.
echo.
echo The bridge will start automatically when this Windows user signs in.
pause
