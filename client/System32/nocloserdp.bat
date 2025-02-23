@echo off
:loop
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Terminal Server Client\Servers\COMPUTERNAME' -Name 'UsernameHint' -Value '' -Type String -Force ; mstsc /prompt /v:COMPUTERNAME" | set /P "="
goto loop