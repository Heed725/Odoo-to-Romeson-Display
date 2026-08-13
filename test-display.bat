@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r=Invoke-RestMethod 'http://127.0.0.1:8765/display?value=25000.00'; Write-Host 'SUCCESS: Display should show 25000.00' -ForegroundColor Green; $r | ConvertTo-Json } catch { Write-Host ('FAILED: '+$_.Exception.Message) -ForegroundColor Red; Write-Host 'Run install.bat or start-bridge.bat, then test again.' }"
pause
