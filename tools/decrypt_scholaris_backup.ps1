param(
    [Parameter(Mandatory = $true)][string] $BackupFile,
    [Parameter(Mandatory = $true)][string] $OutputFile
)
$ErrorActionPreference = 'Stop'
$env:PSModulePath = Join-Path $PSHOME 'Modules'
$backupConfigDir = Join-Path $env:USERPROFILE 'ScholarisBackup'
$backupConfig = Get-Content -LiteralPath (Join-Path $backupConfigDir 'config.json') -Raw | ConvertFrom-Json
$secure = (Get-Content -LiteralPath (Join-Path $backupConfigDir 'encryption.secret') -Raw).Trim() | ConvertTo-SecureString
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $env:SCHOLARIS_BACKUP_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    & $backupConfig.python (Join-Path $PSScriptRoot 'scholaris_backup.py') decrypt $BackupFile $OutputFile
    if ($LASTEXITCODE -ne 0) { throw 'Backup decryption failed.' }
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    Remove-Item Env:SCHOLARIS_BACKUP_KEY -ErrorAction SilentlyContinue
}
