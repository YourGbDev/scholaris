@echo off
setlocal
rem Set this before PowerShell starts, including when launched by Task Scheduler.
set "PSModulePath=%SystemRoot%\System32\WindowsPowerShell\v1.0\Modules"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0run_scholaris_backup.ps1" >> "%USERPROFILE%\ScholarisBackup\scheduled-run.log" 2>&1
exit /b %errorlevel%
