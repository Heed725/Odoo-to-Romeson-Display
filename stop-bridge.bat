@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -like '*romeson-bridge.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
