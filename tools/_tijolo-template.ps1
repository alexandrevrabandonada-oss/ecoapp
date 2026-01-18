$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Carrega funções comuns: EnsureDir / WriteUtf8NoBom / BackupFile / NewReport / FindFirstFileLike / AssertNotNull
. "$PSScriptRoot/_bootstrap.ps1"

$rep = NewReport "eco-STEP-NN-NOME"
$log = @()
$log += "# ECO — STEP NN — NOME"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  # DIAG
  $log += "## DIAG"
  $log += ("Node: {0}" -f (node -v))
  $log += ("Npm : {0}" -f (npm -v))
  $log += ""

  # PATCH
  # - sempre BackupFile antes de editar
  # - sempre Test-Path + AssertNotNull antes de Replace/Insert

  # VERIFY (opcional)
  # npm run lint
  # npm run dev

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ OK. Report -> {0}" -f $rep) -ForegroundColor Green
} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}