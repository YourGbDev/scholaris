$ErrorActionPreference = 'Stop'
# Desktop-launched Windows PowerShell can inherit incompatible PowerShell 7 modules.
$env:PSModulePath = Join-Path $PSHOME 'Modules'
$backupConfigDir = Join-Path $env:USERPROFILE 'ScholarisBackup'
$backupConfig = Get-Content -LiteralPath (Join-Path $backupConfigDir 'config.json') -Raw | ConvertFrom-Json

function Read-ProtectedValue([string] $Path) {
    $secure = (Get-Content -LiteralPath $Path -Raw).Trim() | ConvertTo-SecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}

try {
    $env:SCHOLARIS_DB_URL = Read-ProtectedValue (Join-Path $backupConfigDir 'database.secret')
    $env:SCHOLARIS_BACKUP_KEY = Read-ProtectedValue (Join-Path $backupConfigDir 'encryption.secret')
    $env:SCHOLARIS_BACKUP_DIR = $backupConfig.backupDir
    $env:SCHOLARIS_PG_DUMP = $backupConfig.pgDump
    $env:SCHOLARIS_BACKUP_CA_FILE = $backupConfig.sslRootCert
    $env:SCHOLARIS_BACKUP_MIRROR_DIR = $backupConfig.mirrorDir
    & $backupConfig.python (Join-Path $PSScriptRoot 'scholaris_backup.py')
    if ($LASTEXITCODE -ne 0) { throw 'Encrypted backup failed.' }
} finally {
    Remove-Item Env:SCHOLARIS_DB_URL, Env:SCHOLARIS_BACKUP_KEY, Env:SCHOLARIS_BACKUP_DIR, Env:SCHOLARIS_PG_DUMP, Env:SCHOLARIS_BACKUP_CA_FILE, Env:SCHOLARIS_BACKUP_MIRROR_DIR -ErrorAction SilentlyContinue
}
