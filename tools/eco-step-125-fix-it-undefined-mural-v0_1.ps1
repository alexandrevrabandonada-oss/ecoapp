param(
  [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

function TryDotSourceBootstrap([string]$rootPath) {
  $b1 = Join-Path $rootPath "tools\_bootstrap.ps1"
  if (Test-Path -LiteralPath $b1) {
    try { . $b1; return $true } catch {
      Write-Host ("[WARN] bootstrap falhou, vou usar fallback local: " + $_.Exception.Message)
      return $false
    }
  }
  return $false
}

# --- fallback (caso bootstrap esteja ausente/quebrado)
function EnsureDir([string]$p) {
  if (-not $p) { return }
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$p, [string]$content) {
  EnsureDir (Split-Path -Parent $p)
  [System.IO.File]::WriteAllText($p, $content, [System.Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$p, [string]$backupDir) {
  EnsureDir $backupDir
  if (Test-Path -LiteralPath $p) {
    $leaf = Split-Path -Leaf $p
    $dst = Join-Path $backupDir ($leaf + ".bak")
    Copy-Item -LiteralPath $p -Destination $dst -Force
  }
}

$bootOk = TryDotSourceBootstrap $Root

# se o bootstrap definiu essas funções, ele “vence”
if (Get-Command EnsureDir -ErrorAction SilentlyContinue) { }
if (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue) { }
if (Get-Command BackupFile -ErrorAction SilentlyContinue) { }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$me = "eco-step-125-fix-it-undefined-mural-v0_1"
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

$targets = @(
  (Join-Path $Root "src\app\eco\mural\MuralClient.tsx"),
  (Join-Path $Root "src\app\eco\mural-acoes\MuralAcoesClient.tsx")
)

function HasItDeclaration([string]$raw) {
  if (-not $raw) { return $false }
  if ($raw -match '\b(const|let|var)\s+it\b') { return $true }
  # parâmetro it em arrow/function
  if ($raw -match '\(\s*it\s*[:\),]') { return $true }
  if ($raw -match 'function\s+\w+\s*\(\s*it\b') { return $true }
  return $false
}

function GuessReplacement([string]$raw) {
  if (-not $raw) { return "item" }
  if ($raw -match '\.map\(\(\s*p\b') { return "p" }
  if ($raw -match '\.map\(\(\s*item\b') { return "item" }
  if ($raw -match '\.map\(\(\s*pt\b') { return "pt" }
  if ($raw -match '\.map\(\(\s*point\b') { return "point" }
  # fallback
  return "item"
}

$report = @()
$report += "# $me"
$report += ""
$report += "- Time: $stamp"
$report += "- Backup: $backupDir"
$report += "- Bootstrap: " + ($(if($bootOk){"OK"}else{"fallback/partial"}))
$report += ""

$patched = 0

foreach ($f in $targets) {
  $leaf = Split-Path -Leaf $f
  $report += "## $leaf"
  if (-not (Test-Path -LiteralPath $f)) {
    $report += "- missing: $f"
    $report += ""
    continue
  }

  $raw = Get-Content -Raw -LiteralPath $f
  $hasDecl = HasItDeclaration $raw

  $lines = $raw -split "`n"
  $hitLines = @()
  for ($i=0; $i -lt $lines.Length; $i++) {
    $ln = $lines[$i]
    if ($ln -match '\bit(\.|\?\.|\[)') {
      $hitLines += [pscustomobject]@{ n = ($i+1); t = ($ln.Trim()) }
    }
  }

  $report += "- hasDeclIt: " + $hasDecl
  $report += "- hits(it./it?. /it[): " + $hitLines.Count
  foreach ($h in $hitLines) {
    $report += ("  - L" + $h.n + ": " + $h.t)
  }

  if ($hitLines.Count -eq 0) {
    $report += ""
    continue
  }

  if ($hasDecl) {
    $report += "- skip patch (it já parece declarado como param/var)"
    $report += ""
    continue
  }

  $rep = GuessReplacement $raw
  $newLines = @()

  foreach ($ln in $lines) {
    $x = $ln
    if ($x -match '\bit(\.|\?\.|\[)') {
      # troca conservadora só nas formas it., it?. e it[
      $x = $x -replace '\bit\?\.', ($rep + '?.')
      $x = $x -replace '\bit\.',   ($rep + '.')
      $x = $x -replace '\bit\[',   ($rep + '[')
    }
    $newLines += $x
  }

  $new = ($newLines -join "`n")
  if ($new -ne $raw) {
    BackupFile $f $backupDir
    WriteUtf8NoBom $f $new
    $patched++
    $report += "- patched: replaced it.* -> " + $rep + ".*"
  } else {
    $report += "- no changes needed"
  }
  $report += ""
}

$report += "## Summary"
$report += "- patchedFiles: $patched"
$report += ""
$report += "## Verify"
$report += "1) Ctrl+C -> npm run dev"
$report += "2) abrir /eco/mural (sem 'it is not defined')"
$report += "3) abrir /eco/mapa"
$report += ""

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)
Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  abrir /eco/mapa"