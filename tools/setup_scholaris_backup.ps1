param(
    [Parameter(Mandatory = $true)][string] $PgDump,
    [Parameter(Mandatory = $true)][string] $PythonPath,
    [string] $BackupDirectory = (Join-Path $env:USERPROFILE 'ScholarisBackup\archives')
)
$ErrorActionPreference = 'Stop'
$env:PSModulePath = Join-Path $PSHOME 'Modules'
$backupConfigDir = Join-Path $env:USERPROFILE 'ScholarisBackup'
if (!(Test-Path -LiteralPath $PgDump -PathType Leaf) -or !(Test-Path -LiteralPath $PythonPath -PathType Leaf)) {
    throw 'Specify existing pg_dump and Python executable paths.'
}
if (!(Test-Path -LiteralPath (Join-Path $backupConfigDir 'config.json'))) {
    if ((Test-Path -LiteralPath (Join-Path $backupConfigDir 'database.secret')) -or (Test-Path -LiteralPath (Join-Path $backupConfigDir 'encryption.secret'))) {
        throw 'Partial backup configuration exists. Preserve the existing secrets and repair it manually.'
    }
    $database = Read-Host 'Paste the Supabase PostgreSQL connection URL (input is hidden)' -AsSecureString
    if ($database.Length -eq 0) { throw 'No connection URL was entered.' }
    New-Item -ItemType Directory -Path $backupConfigDir -Force | Out-Null
    $keyBytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($keyBytes) } finally { $rng.Dispose() }
    $keySecure = ConvertTo-SecureString ([Convert]::ToBase64String($keyBytes)) -AsPlainText -Force
    [Array]::Clear($keyBytes, 0, $keyBytes.Length)
    $database | ConvertFrom-SecureString | Set-Content -LiteralPath (Join-Path $backupConfigDir 'database.secret')
    $keySecure | ConvertFrom-SecureString | Set-Content -LiteralPath (Join-Path $backupConfigDir 'encryption.secret')
    @{ pgDump = (Resolve-Path -LiteralPath $PgDump).Path; python = (Resolve-Path -LiteralPath $PythonPath).Path; backupDir = $BackupDirectory } |
        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backupConfigDir 'config.json')
} else {
    Write-Output 'Reusing existing protected backup configuration.'
}

# A failed first backup prevents scheduling a job that has never succeeded.
& (Join-Path $PSScriptRoot 'run_scholaris_backup.ps1')
$runner = Join-Path $PSScriptRoot 'run_scholaris_backup.cmd'
$action = New-ScheduledTaskAction -Execute (Join-Path $env:WINDIR 'System32\cmd.exe') -Argument ('/d /c call "' + $runner + '"') -WorkingDirectory $PSScriptRoot
$trigger = New-ScheduledTaskTrigger -Daily -At '02:00'
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'Scholaris encrypted daily database backup' -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
Write-Output 'Daily backup scheduled for this Windows user while signed in.'
