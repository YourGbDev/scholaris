$ErrorActionPreference = 'Stop'
$testDirectory = Join-Path ([IO.Path]::GetTempPath()) ('scholaris-protected-test-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $testDirectory | Out-Null
try {
    $sample = ConvertTo-SecureString 'test-only-not-a-credential' -AsPlainText -Force
    $serialized = $sample | ConvertFrom-SecureString
    foreach ($scriptName in @('run_scholaris_backup.ps1', 'decrypt_scholaris_backup.ps1')) {
        $scriptPath = Join-Path (Split-Path $PSScriptRoot) ('tools\' + $scriptName)
        $ast = [Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$null)
        $assignment = $ast.Find({ param($node)
            $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$secure'
        }, $true)
        if (!$assignment) { throw "Protected-value reader missing: $scriptName" }
        foreach ($ending in @('', "`r`n")) {
            $backupConfigDir = $testDirectory
            $Path = Join-Path $testDirectory 'encryption.secret'
            [IO.File]::WriteAllText($Path, $serialized + $ending)
            $restored = Invoke-Expression $assignment.Right.Extent.Text
            if ($restored -isnot [Security.SecureString] -or $restored.Length -ne $sample.Length) {
                throw "Protected-value round-trip failed: $scriptName"
            }
        }
        Write-Output "PASS: $scriptName reads protected values with and without a trailing newline"
    }
} finally {
    # Only remove the two known test artifacts; never touch real backup secrets.
    Remove-Item -LiteralPath (Join-Path $testDirectory 'encryption.secret') -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testDirectory
}
