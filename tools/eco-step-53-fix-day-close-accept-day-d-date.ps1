$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --- bootstrap (preferido) ---
$bootstrap = "tools/_bootstrap.ps1"
if(Test-Path -LiteralPath $bootstrap){ . $bootstrap } else {
  function EnsureDir([string]$p){ if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
  function WriteUtf8NoBom([string]$path, [string]$content){ $dir = Split-Path -Parent $path; if($dir){ EnsureDir $dir }; $utf8NoBom = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($path, $content, $utf8NoBom) }
  function BackupFile([string]$path){ if(!(Test-Path -LiteralPath $path)){ return $null }; EnsureDir "tools/_patch_backup"; $ts = Get-Date -Format "yyyyMMdd-HHmmss"; $safe = ($path -replace '[\\/:*?"<>|]','_'); $dst = "tools/_patch_backup/$ts-$safe"; Copy-Item -Force -LiteralPath $path $dst; return $dst }
  function NewReport([string]$name){ EnsureDir "reports"; $ts = Get-Date -Format "yyyyMMdd-HHmmss"; return "reports/$ts-$name.md" }
}

$rep = NewReport "eco-step-53-fix-day-close-accept-day-d-date"
$log = @()
$log += "# ECO — STEP 53 — Fix day-close param (aceitar day/d/date)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  $dayClose = "src/app/api/eco/day-close/route.ts"
  if(!(Test-Path -LiteralPath $dayClose)){ throw "Não achei: $dayClose" }

  $raw = Get-Content -LiteralPath $dayClose -Raw
  if([string]::IsNullOrWhiteSpace($raw)){ throw "Arquivo vazio: $dayClose" }

  $bk = BackupFile $dayClose
  $log += "## Backup"
  $log += ("- {0}" -f $bk)
  $log += ""

  $raw2 = $raw
  $before = $raw2

  # Alvo: qualquer safeDay(searchParams.get("d")) ou safeDay(searchParams.get("date"))
  $raw2 = $raw2 -replace 'safeDay\(\s*searchParams\.get\("d"\)\s*\)', 'safeDay(searchParams.get("day") ?? searchParams.get("d") ?? searchParams.get("date"))'
  $raw2 = $raw2 -replace "safeDay\\(\\s*searchParams\\.get\\('d'\\)\\s*\\)", "safeDay(searchParams.get(\"day\") ?? searchParams.get(\"d\") ?? searchParams.get(\"date\"))"
  $raw2 = $raw2 -replace 'safeDay\(\s*searchParams\.get\("date"\)\s*\)', 'safeDay(searchParams.get("day") ?? searchParams.get("d") ?? searchParams.get("date"))'
  $raw2 = $raw2 -replace "safeDay\\(\\s*searchParams\\.get\\('date'\\)\\s*\\)", "safeDay(searchParams.get(\"day\") ?? searchParams.get(\"d\") ?? searchParams.get(\"date\"))"

  $changed = ($raw2 -ne $before)
  $log += "## PATCH"
  $log += ("- Changed: {0}" -f $changed)
  $log += ""

  if($changed){
    WriteUtf8NoBom $dayClose $raw2
    $log += "- OK: day-close agora aceita day/d/date."
  } else {
    $log += "- INFO: não encontrei padrão safeDay(searchParams.get(\"d\"/\"date\")) para substituir (talvez já esteja OK)."
  }
  $log += ""

  $log += "## DIAG (linhas com searchParams.get)"
  $rawNow = Get-Content -LiteralPath $dayClose -Raw
  $diag = ($rawNow -split "`n" | Where-Object { $_ -match "searchParams\.get" })
  if($diag.Count -gt 0){ $log += ($diag | Select-Object -First 20) } else { $log += "(nenhuma)" }
  $log += ""

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 53 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) Reinicie o dev (CTRL+C e npm run dev)" -ForegroundColor Yellow
  Write-Host "2) GET /api/eco/day-close?day=2025-12-26 (não pode ser 400)" -ForegroundColor Yellow
  Write-Host "3) (extra) GET /api/eco/day-close?d=2025-12-26 (também deve funcionar)" -ForegroundColor Yellow
} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}
