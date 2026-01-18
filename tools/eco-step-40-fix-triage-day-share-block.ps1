$ErrorActionPreference = 'Stop'

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ EnsureDir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}
function BackupFile([string]$path){
  if(!(Test-Path -LiteralPath $path)){ return $null }
  EnsureDir 'tools/_patch_backup'
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir 'reports'
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  return "reports/$ts-$name.md"
}
function FindFirst([string]$root, [string]$endsWith){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*$endsWith" } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport 'eco-step-40-fix-triage-day-share-block'
$log = @()
$log += '# ECO — STEP 40 — Fix triagem (bloco STEP38) + smoke share day'
$log += ''
$log += ('Data: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$log += ('PWD : {0}' -f (Get-Location).Path)
$log += ''

# -------------------------
# PATCH 1) OperatorTriageV2.tsx — corrigir bloco STEP38
# -------------------------
$tri = 'src/app/operador/triagem/OperatorTriageV2.tsx'
if(!(Test-Path -LiteralPath $tri)){
  $tri = FindFirst '.' '\src\app\operador\triagem\OperatorTriageV2.tsx'
}
if(!(Test-Path -LiteralPath $tri)){
  $log += '## WARN'
  $log += 'Não achei OperatorTriageV2.tsx — pulei triagem.'
} else {
  $bkT = BackupFile $tri
  $txtT = Get-Content -LiteralPath $tri -Raw

  $log += '## PATCH — TRIAGEM'
  $log += ('Arquivo: {0}' -f $tri)
  $log += ('Backup : {0}' -f $bkT)

  $startMark = '/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_START */'
  $endMark   = '/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_END */'

  $fixedBlock = @(
    '/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_START */',
    'const ecoDayPublicSharePath = () => `/s/dia/${encodeURIComponent(routeDay)}`;',
    'const ecoDayPublicShareUrl = () => {',
    '  try {',
    '    return window.location.origin + ecoDayPublicSharePath();',
    '  } catch {',
    '    return ecoDayPublicSharePath();',
    '  }',
    '};',
    '',
    'const onOpenDaySharePage = () => {',
    '  window.open(ecoDayPublicSharePath(), "_blank", "noopener,noreferrer");',
    '};',
    '',
    'const onCopyDayShareLink = async () => {',
    '  const link = ecoDayPublicShareUrl();',
    '  try {',
    '    await navigator.clipboard.writeText(link);',
    '    alert("Link copiado!");',
    '  } catch {',
    '    prompt("Copie o link:", link);',
    '  }',
    '};',
    '',
    'const onWaDayShareLink = () => {',
    '  const link = ecoDayPublicShareUrl();',
    '  const text = `ECO — Fechamento do dia ${routeDay}\n${link}`;',
    '  const wa = `https://wa.me/?text=${encodeURIComponent(text)}`;',
    '  window.open(wa, "_blank", "noopener,noreferrer");',
    '};',
    '/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_END */'
  ) -join "`n"

  $start = $txtT.IndexOf($startMark)
  $end   = $txtT.IndexOf($endMark)

  if($start -ge 0 -and $end -ge 0 -and $end -gt $start){
    $after = $end + $endMark.Length
    $txtT = $txtT.Substring(0, $start) + $fixedBlock + $txtT.Substring($after)
    $log += '- OK: bloco STEP38 substituído entre markers.'
  } else {
    # fallback: corrigir a linha quebrada se existir
    if($txtT.Contains('const ecoDayPublicSharePath = () => /s/dia/;')){
      $txtT = $txtT.Replace(
        'const ecoDayPublicSharePath = () => /s/dia/;',
        'const ecoDayPublicSharePath = () => `/s/dia/${encodeURIComponent(routeDay)}`;'
      )
      $log += '- OK: corrigi a linha quebrada (fallback).'
    } else {
      $log += '- WARN: não achei markers nem a linha quebrada exata (nada alterado).'
    }
  }

  # Garantia extra: se sobrou algum "=> /s/dia/" (sem crase), corrige
  if($txtT.Contains('=> /s/dia/')){
    $txtT = $txtT.Replace('=> /s/dia/', '=> `/s/dia/')
    $log += '- OK: correção extra aplicada (sobrou "=> /s/dia/").'
  }

  WriteUtf8NoBom $tri $txtT
  $log += '- OK: triagem salva.'
}

$log += ''

# -------------------------
# PATCH 2) Smoke dedicado: tools/eco-smoke-share-day.ps1
# -------------------------
$smokePath = 'tools/eco-smoke-share-day.ps1'
$bkS = BackupFile $smokePath

$log += '## PATCH — SMOKE (share day)'
$log += ('Arquivo: {0}' -f $smokePath)
$log += ('Backup : {0}' -f ($bkS ? $bkS : '(novo)'))

$smokeTxtLines = @(
  '$ErrorActionPreference = ''Stop''',
  '',
  'Write-Host ''== ECO SMOKE — SHARE DAY =='' -ForegroundColor Cyan',
  '$BaseUrl = ''http://localhost:3000''',
  '$today = (Get-Date -Format ''yyyy-MM-dd'')',
  '',
  '$paths = @(',
  '  "/s/dia/$today",',
  '  "/api/share/route-day-card?day=$today&format=3x4",',
  '  "/api/share/route-day-card?day=$today&format=1x1",',
  '  "/operador/triagem"',
  ')',
  '',
  'foreach($p in $paths){',
  '  $url = $BaseUrl + $p',
  '  try {',
  '    $res = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing',
  '    $sc = [int]$res.StatusCode',
  '    if($sc -ge 200 -and $sc -lt 300){',
  '      Write-Host ("OK {0} -> {1}" -f $sc, $p) -ForegroundColor Green',
  '    } else {',
  '      Write-Host ("FAIL {0} -> {1}" -f $sc, $p) -ForegroundColor Red',
  '      exit 1',
  '    }',
  '  } catch {',
  '    Write-Host ("ERR -> {0}" -f $p) -ForegroundColor Red',
  '    Write-Host ($_.Exception.Message) -ForegroundColor DarkRed',
  '    exit 1',
  '  }',
  '}',
  '',
  'Write-Host ''OK: smoke share day concluído'' -ForegroundColor Green'
)

WriteUtf8NoBom $smokePath ($smokeTxtLines -join "`n")
$log += '- OK: eco-smoke-share-day.ps1 criado/atualizado.'
$log += ''

$log += '## VERIFY'
$log += '1) CTRL+C ; npm run dev'
$log += '2) Abra /operador/triagem (deve 200)'
$log += '3) Teste os botões do link público do dia'
$log += '4) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke-share-day.ps1'

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 40 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host 'PRÓXIMOS PASSOS:' -ForegroundColor Yellow
Write-Host '1) CTRL+C ; npm run dev' -ForegroundColor Yellow
Write-Host '2) Abra /operador/triagem' -ForegroundColor Yellow
Write-Host '3) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke-share-day.ps1' -ForegroundColor Yellow