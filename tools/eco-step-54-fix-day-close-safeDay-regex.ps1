$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$bootstrap = "tools/_bootstrap.ps1"
if(Test-Path -LiteralPath $bootstrap){ . $bootstrap } else {
  function EnsureDir([string]$p){ if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
  function WriteUtf8NoBom([string]$path, [string[]]$lines){
    $dir = Split-Path -Parent $path; if($dir){ EnsureDir $dir }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($path, $lines, $utf8NoBom)
  }
  function BackupFile([string]$path){ if(!(Test-Path -LiteralPath $path)){ return $null }
    EnsureDir "tools/_patch_backup"; $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $safe = ($path -replace '[\\/:*?"<>|]','_')
    $dst = "tools/_patch_backup/$ts-$safe"; Copy-Item -Force -LiteralPath $path $dst; return $dst
  }
  function NewReport([string]$name){ EnsureDir "reports"; $ts = Get-Date -Format "yyyyMMdd-HHmmss"; return "reports/$ts-$name.md" }
}

function ReplaceFuncBlock([string]$raw, [string]$marker, [string]$replacement){
  $idx = $raw.IndexOf($marker)
  if($idx -lt 0){ return $null }
  $braceStart = $raw.IndexOf("{", $idx)
  if($braceStart -lt 0){ throw "Nao achei { apos $marker" }
  $depth = 0
  $end = -1
  for($i=$braceStart; $i -lt $raw.Length; $i++){
    $ch = $raw[$i]
    if($ch -eq "{"){ $depth++ }
    elseif($ch -eq "}"){ $depth--; if($depth -eq 0){ $end = $i; break } }
  }
  if($end -lt 0){ throw "Nao consegui fechar bloco de $marker (brace matching falhou)" }
  $before = $raw.Substring(0, $idx)
  $after  = $raw.Substring($end + 1)
  return ($before + $replacement + $after)
}

$rep = NewReport "eco-step-54-fix-day-close-safeDay-regex"
$log = @()
$log += "# ECO — STEP 54 — Fix safeDay() (regex) + query day/d/date"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  if(!(Test-Path -LiteralPath "src/app/api/eco/day-close/route.ts")){ throw "GUARD: nao achei src/app/api/eco/day-close/route.ts" }

  $targets = @(
    "src/app/api/eco/day-close/route.ts",
    "src/app/api/eco/day-close/compute/route.ts"
  )

  $safeFunc = (@(
    "function safeDay(input: string | null): string | null {",
    "  const s = String(input || """").trim();",
    "  if (/^\\d{4}-\\d{2}-\\d{2}$/.test(s)) return s;",
    "  return null;",
    "}",
    ""
  ) -join "`n")

  foreach($file in $targets){
    if(!(Test-Path -LiteralPath $file)){
      $log += ("- SKIP: {0} (nao existe)" -f $file)
      continue
    }

    $raw = Get-Content -Raw -LiteralPath $file
    if($null -eq $raw -or $raw.Length -lt 10){ throw "Arquivo vazio/estranho: $file" }
    $bk = BackupFile $file
    $log += "## PATCH — $file"
    $log += ("Backup: {0}" -f ($(if($bk){$bk}else{"(novo)"})))

    $newRaw = $raw

    # 1) Corrigir safeDay() por brace-matching
    if($newRaw.Contains("function safeDay(")){
      $tmp = ReplaceFuncBlock $newRaw "function safeDay" $safeFunc
      if($null -ne $tmp){ $newRaw = $tmp; $log += "- OK: safeDay() reescrito (regex correto com \\d)." }
      else { $log += "- WARN: nao consegui substituir safeDay() por marker (idx=-1?)" }
    } else {
      $log += "- INFO: nao achei function safeDay() aqui."
    }

    # 2) Garantir query aceita day/d/date (quando existir const day = safeDay(searchParams.get("day")) ...)
    $needle = "const day = safeDay(searchParams.get(""day""));"
    $want   = "const day = safeDay(searchParams.get(""day"") ?? searchParams.get(""d"") ?? searchParams.get(""date""));"
    if($newRaw.Contains($needle)){
      $newRaw = $newRaw.Replace($needle, $want)
      $log += "- OK: query day agora aceita day/d/date."
    }

    # 3) (extra) se alguém escapou demais e deixou \\d dentro de regex literal, corrigir um padrão comum
    $newRaw = $newRaw.Replace("/^\\\\d{4}-\\\\d{2}-\\\\d{2}$/", "/^\\d{4}-\\d{2}-\\d{2}$/")

    if($newRaw -ne $raw){
      WriteUtf8NoBom $file ($newRaw -split "`n")
      $log += "- OK: gravado."
    } else {
      $log += "- OK: nada mudou (ja estava certo)."
    }
    $log += ""
  }

  WriteUtf8NoBom $rep $log
  Write-Host ("✅ STEP 54 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) Reinicie o dev server (CTRL+C, npm run dev)" -ForegroundColor Yellow
  Write-Host "2) irm http://localhost:3000/api/eco/day-close?day=2025-12-26 | ConvertTo-Json -Depth 20" -ForegroundColor Yellow
  Write-Host "   Esperado: nao pode mais ser bad_day (deve vir 404/200/503)" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep $log } catch {}
  throw
}
