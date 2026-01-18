$ErrorActionPreference = "Stop"
. "$PSScriptRoot/_eco-lib.ps1"

$rep = NewReport "eco-step-XX-NOME"
$log = @()
$log += "# ECO — STEP XX — Nome do passo"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# DIAG -> localizar arquivos com FindFirst / Contains
# PATCH -> BackupFile + WriteUtf8NoBom
# VERIFY -> (orientar smoke)

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP XX pronto. Report -> {0}" -f $rep) -ForegroundColor Green