$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$boot = Join-Path $PSScriptRoot "_bootstrap.ps1"
if(Test-Path -LiteralPath $boot){ . $boot } else {
  function EnsureDir([string]$p){ if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
  function WriteUtf8NoBom([string]$p,[string]$c){ $d=Split-Path -Parent $p; if($d){EnsureDir $d}; $u=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($p,$c,$u) }
  function BackupFile([string]$p){ if(!(Test-Path -LiteralPath $p)){return $null}; EnsureDir "tools/_patch_backup"; $ts=Get-Date -Format "yyyyMMdd-HHmmss"; $safe=($p -replace '[\\/:*?"<>|]','_'); $dst="tools/_patch_backup/$ts-$safe"; Copy-Item -Force -LiteralPath $p $dst; return $dst }
  function NewReport([string]$n){ EnsureDir "reports"; $ts=Get-Date -Format "yyyyMMdd-HHmmss"; return "reports/$ts-$n.md" }
}

function ReplaceFunctionByBraceMatch([string]$raw,[string]$fnName,[string]$newFn){
  $idx = $raw.IndexOf("function " + $fnName)
  if($idx -lt 0){ return @{ ok=$false; raw=$raw; msg=("nao achei function " + $fnName) } }
  $braceStart = $raw.IndexOf("{", $idx)
  if($braceStart -lt 0){ return @{ ok=$false; raw=$raw; msg="nao achei { da funcao" } }
  $depth = 0
  $i = $braceStart
  for(; $i -lt $raw.Length; $i++){
    $ch = $raw[$i]
    if($ch -eq "{"){ $depth++ }
    elseif($ch -eq "}"){ $depth--; if($depth -eq 0){ break } }
  }
  if($depth -ne 0){ return @{ ok=$false; raw=$raw; msg="brace matching falhou (depth != 0)" } }
  $end = $i
  # pega do "function safeDay" até o "}" final
  $start = $idx
  $old = $raw.Substring($start, ($end - $start + 1))
  $patched = $raw.Remove($start, ($end - $start + 1)).Insert($start, $newFn)
  return @{ ok=$true; raw=$patched; old=$old }
}

$rep = NewReport "eco-step-54-fix-safeDay-normalize-day-close"
$log = @()
$log += "# ECO — STEP 54 — Fix safeDay (normalize day)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  $targets = @(
    "src/app/api/eco/day-close/route.ts",
    "src/app/api/eco/day-close/compute/route.ts"
  )

  $newFn = @(
    "function safeDay(input: string | null): string | null {",
    "  const raw = String(input ?? \"\").trim();",
    "  if (!raw) return null;",
    "  const head10 = raw.length >= 10 ? raw.slice(0, 10) : raw;",
    "  let m = head10.match(/^(\d{4})[-\/](\d{2})[-\/](\d{2})$/);",
    "  if (m) return `${m[1]}-${m[2]}-${m[3]}`;",
    "  m = raw.match(/^(\d{4})(\d{2})(\d{2})$/);",
    "  if (m) return `${m[1]}-${m[2]}-${m[3]}`;",
    "  m = raw.match(/^(\d{2})[-\/](\d{2})[-\/](\d{4})$/);",
    "  if (m) return `${m[3]}-${m[2]}-${m[1]}`;",
    "  return null;",
    "}"
  ) -join "`n"

  foreach($t in $targets){
    if(!(Test-Path -LiteralPath $t)){
      $log += ("- SKIP: nao achei {0}" -f $t)
      continue
    }
    $raw = Get-Content -LiteralPath $t -Raw
    $bk = BackupFile $t
    $log += ("## PATCH: {0}" -f $t)
    $log += ("Backup: {0}" -f $bk)

    $res = ReplaceFunctionByBraceMatch $raw "safeDay" $newFn
    if(!$res.ok){
      $log += ("- FAIL: {0}" -f $res.msg)
      $log += ""
      continue
    }
    WriteUtf8NoBom $t $res.raw
    $log += "- OK: safeDay normalizado (aceita YYYY-MM-DD, YYYY/MM/DD, YYYYMMDD, DD/MM/YYYY, ISO com hora)"
    $log += ""
  }

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 54 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) (se dev rodando) CTRL+C e npm run dev" -ForegroundColor Yellow
  Write-Host "2) irm http://localhost:3000/api/eco/day-close?day=2025-12-26 | ConvertTo-Json" -ForegroundColor Yellow
  Write-Host "   esperado: 404 (se nao tiver row) OU 200 (se tiver), mas NAO bad_day" -ForegroundColor Yellow
} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}
