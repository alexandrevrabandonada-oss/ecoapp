param([switch]$OpenReport)

if (!(Test-Path "package.json")) { throw "Rode na raiz do repo (onde tem package.json)." }

$bootstrap = Join-Path $PSScriptRoot "_bootstrap.ps1"
if (Test-Path $bootstrap) {
  . $bootstrap
} else {
  function EnsureDir([string]$p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
  function WriteUtf8NoBom([string]$path, [string]$content){
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
  }
  function BackupFile([string]$path, [string]$backupDir){
    EnsureDir $backupDir
    $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $name = ($path -replace "[:\\\/]", "_")
    $dest = Join-Path $backupDir ($stamp + "-" + $name)
    Copy-Item -LiteralPath $path -Destination $dest -Force
    return $dest
  }
}

$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
EnsureDir "reports"
$reportPath = Join-Path "reports" ("eco-step-192-fix-receiptsharebar-downloadcard-" + $stamp + ".md")

$target = "src\components\eco\ReceiptShareBar.tsx"
if (!(Test-Path -LiteralPath $target)) { throw "Nao achei: $target" }

$raw = Get-Content -Raw -Encoding UTF8 -LiteralPath $target

$hasCall = [regex]::IsMatch($raw, "\beco28_downloadCard\s*\(")
$hasDef  = [regex]::IsMatch($raw, "(?m)^\s*(async\s+)?function\s+eco28_downloadCard\b|^\s*const\s+eco28_downloadCard\b")

$log = ""
if (-not $hasCall) {
  $log += "[SKIP] nao achei chamada eco28_downloadCard( ) no arquivo.`n"
  $out = $raw
} elseif ($hasDef) {
  $log += "[SKIP] funcao eco28_downloadCard ja existe.`n"
  $out = $raw
} else {
  $nl = "`n"
  if ($raw -match "`r`n") { $nl = "`r`n" }
  $lines = $raw -split "\r?\n", -1

  $insertAfter = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '^\s*["'']use client["''];\s*$') { $insertAfter = $i; break }
  }
  if ($insertAfter -lt 0) {
    $lastImport = -1
    for ($i=0; $i -lt $lines.Length; $i++) { if ($lines[$i] -match '^\s*import\s+') { $lastImport = $i } }
    if ($lastImport -ge 0) { $insertAfter = $lastImport } else { $insertAfter = 0 }
  }

  $block = @(
    "",
    'function eco28_downloadCard(code: string, format: "1x1" | "3x4" = "3x4") {',
    '  const c = encodeURIComponent(String(code || ""));',
    '  const f = encodeURIComponent(String(format || "3x4"));',
    '  const url = "/api/share/receipt-card?code=" + c + "&format=" + f;',
    '  const a = document.createElement("a");',
    '  a.href = url;',
    '  a.download = "eco-recibo-" + c + "-" + String(format || "3x4") + ".png";',
    '  document.body.appendChild(a);',
    '  a.click();',
    '  a.remove();',
    '}',
    ""
  )

  $rebuilt = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines.Length; $i++) {
    $rebuilt.Add($lines[$i]) | Out-Null
    if ($i -eq $insertAfter) {
      foreach ($b in $block) { $rebuilt.Add($b) | Out-Null }
    }
  }

  $out = ($rebuilt.ToArray() -join $nl)

  $bakDir = Join-Path "tools\_patch_backup" ("eco-step-192\" + $stamp)
  $bak = BackupFile $target $bakDir
  WriteUtf8NoBom $target $out
  $log += "[OK] inseriu funcao eco28_downloadCard; backup: $bak`n"
}

$r = @()
$r += "# eco-step-192 — fix ReceiptShareBar eco28_downloadCard — $stamp"
$r += ""
$r += "## DIAG"
$r += "- alvo: $target"
$r += "- call eco28_downloadCard(): " + ($hasCall)
$r += "- def eco28_downloadCard: " + ($hasDef)
$r += ""
$r += "## PATCH"
$r += "~~~"
$r += $log.TrimEnd()
$r += "~~~"
$r += ""
$r += "## VERIFY"
$r += "- npm run build"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if ($OpenReport) { try { Start-Process $reportPath | Out-Null } catch {} }