$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# bootstrap (preferencial)
$bootstrap = "tools/_bootstrap.ps1"
if(Test-Path -LiteralPath $bootstrap){ . $bootstrap }
else {
  function EnsureDir([string]$p){ if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
  function WriteUtf8NoBom([string]$path, [string]$content){ $dir = Split-Path -Parent $path; if($dir){ EnsureDir $dir }; $utf8NoBom = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($path, $content, $utf8NoBom) }
  function BackupFile([string]$path){ if(!(Test-Path -LiteralPath $path)){ return $null }; EnsureDir "tools/_patch_backup"; $ts = Get-Date -Format "yyyyMMdd-HHmmss"; $safe = ($path -replace '[\\/:*?"<>|]','_'); $dst = "tools/_patch_backup/$ts-$safe"; Copy-Item -Force -LiteralPath $path $dst; return $dst }
  function NewReport([string]$name){ EnsureDir "reports"; $ts = Get-Date -Format "yyyyMMdd-HHmmss"; return "reports/$ts-$name.md" }
}

$rep = NewReport "eco-step-53b-fix-day-close-accept-day-d-date"
$log = @()
$log += "# ECO — STEP 53B — Fix day-close aceitar day/d/date"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  $file = "src/app/api/eco/day-close/route.ts"
  if(!(Test-Path -LiteralPath $file)){ throw "Não achei: $file" }

  $raw = Get-Content -LiteralPath $file -Raw
  if([string]::IsNullOrWhiteSpace($raw)){ throw "Arquivo vazio/indisponível: $file" }

  $bk = BackupFile $file
  $log += "## Backup"
  $log += ("- {0}" -f ($(if($bk){$bk}else{"(sem backup)"})))
  $log += ""

  # alvo principal: const day = safeDay(searchParams.get("X"));
  $pattern = 'const\s+day\s*=\s*safeDay\(\s*searchParams\.get\(".*?"\)\s*\)\s*;'
  $replacement = 'const day = safeDay(searchParams.get("day") ?? searchParams.get("d") ?? searchParams.get("date"));'

  if($raw -match $pattern){
    $raw2 = [regex]::Replace($raw, $pattern, $replacement)
    WriteUtf8NoBom $file $raw2
    $log += "## PATCH"
    $log += "- OK: normalizei const day para aceitar day/d/date."
    $log += ""
  } else {
    # fallback: troca chamadas específicas safeDay(searchParams.get("d")) / ("date")
    $raw2 = $raw
    $raw2 = $raw2 -replace 'safeDay\(\s*searchParams\.get\("d"\)\s*\)','safeDay(searchParams.get("day") ?? searchParams.get("d") ?? searchParams.get("date"))'
    $raw2 = $raw2 -replace 'safeDay\(\s*searchParams\.get\("date"\)\s*\)','safeDay(searchParams.get("day") ?? searchParams.get("d") ?? searchParams.get("date"))'
    if($raw2 -ne $raw){
      WriteUtf8NoBom $file $raw2
      $log += "## PATCH"
      $log += "- OK: fallback aplicado (safeDay(get(d/date)) -> safeDay(get(day/d/date)))."
      $log += ""
    } else {
      $log += "## PATCH"
      $log += "- INFO: padrão não encontrado; nada alterado."
      $log += ""
    }
  }

  $now = Get-Content -LiteralPath $file -Raw
  $log += "## DIAG (trechos com day)"
  ($now -split "`n" | Where-Object { $_ -match "const day|searchParams\.get" } | Select-Object -First 60) | ForEach-Object { $log += $_ }
  $log += ""

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 53B aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) Reinicie o dev (CTRL+C e npm run dev)" -ForegroundColor Yellow
  Write-Host "2) GET /api/eco/day-close?day=2025-12-26 (não pode ser 400)" -ForegroundColor Yellow
  Write-Host "3) GET /api/eco/day-close?d=2025-12-26 (opcional, deve funcionar igual)" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}
