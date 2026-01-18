$ErrorActionPreference = 'Stop'

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
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
  $safe = ($path -replace '[\\/:*?"<>|]','_')
  $dst = 'tools/_patch_backup/' + $ts + '-' + $safe
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function FindFirst([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

Write-Host '== HOTFIX 38g ==' -ForegroundColor Cyan

# -------------------------
# 1) TRIAGEM: substituir bloco STEP38 inteiro (evita regex /s/dia/)
# -------------------------
$tri = 'src/app/operador/triagem/OperatorTriageV2.tsx'
if(!(Test-Path -LiteralPath $tri)){ $tri = FindFirst '.' '\\src\\app\\operador\\triagem\\OperatorTriageV2\.tsx$' }

if(!(Test-Path -LiteralPath $tri)){
  Write-Host 'WARN: OperatorTriageV2.tsx não encontrado (skip triagem)' -ForegroundColor Yellow
} else {
  $bk = BackupFile $tri
  $txt = Get-Content -LiteralPath $tri -Raw

  $startMark = '/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_START */'
  $endMark   = '/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_END */'
  $s = $txt.IndexOf($startMark)
  $e = $txt.IndexOf($endMark)

  $fixedBlock = @(
    '/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_START */'
    'const ecoDayPublicSharePath = () => `/s/dia/${encodeURIComponent(routeDay)}`;'
    'const ecoDayPublicShareUrl = () => {'
    '  try {'
    '    return window.location.origin + ecoDayPublicSharePath();'
    '  } catch {'
    '    return ecoDayPublicSharePath();'
    '  }'
    '};'
    ''
    'const onOpenDaySharePage = () => {'
    '  window.open(ecoDayPublicSharePath(), "_blank", "noopener,noreferrer");'
    '};'
    ''
    'const onCopyDayShareLink = async () => {'
    '  const link = ecoDayPublicShareUrl();'
    '  try {'
    '    await navigator.clipboard.writeText(link);'
    '    alert("Link copiado!");'
    '  } catch {'
    '    prompt("Copie o link:", link);'
    '  }'
    '};'
    ''
    'const onWaDayShareLink = () => {'
    '  const link = ecoDayPublicShareUrl();'
    '  const text = `ECO — Fechamento do dia ${routeDay}\n${link}`;'
    '  const wa = `https://wa.me/?text=${encodeURIComponent(text)}`;'
    '  window.open(wa, "_blank", "noopener,noreferrer");'
    '};'
    '/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_END */'
  ) -join "`n"

  if($s -ge 0 -and $e -ge 0 -and $e -gt $s){
    $e2 = $e + $endMark.Length
    $txt2 = $txt.Substring(0, $s) + $fixedBlock + $txt.Substring($e2)
    WriteUtf8NoBom $tri $txt2
    Write-Host ('OK: bloco STEP38 substituído -> ' + $tri) -ForegroundColor Green
  } else {
    # fallback: tenta corrigir a linha quebrada mesmo sem markers
    $txt2 = $txt.Replace('const ecoDayPublicSharePath = () => /s/dia/;','const ecoDayPublicSharePath = () => `/s/dia/${encodeURIComponent(routeDay)}`;')
    $txt2 = $txt2.Replace('=> /s/dia/;','=> `/s/dia/${encodeURIComponent(routeDay)}`;')
    if($txt2 -ne $txt){
      WriteUtf8NoBom $tri $txt2
      Write-Host ('OK: fallback corrigiu /s/dia/ na triagem -> ' + $tri) -ForegroundColor Green
    } else {
      Write-Host 'WARN: não achei markers nem linha exata para corrigir na triagem' -ForegroundColor Yellow
    }
  }
}

# -------------------------
# 2) (BÔNUS) SHARE route-day-card: ajustar headers() para Next 16 (se existir)
# -------------------------
$rdc = 'src/app/api/share/route-day-card/route.ts'
if(!(Test-Path -LiteralPath $rdc)){ $rdc = FindFirst '.' '\\src\\app\\api\\share\\route-day-card\\route\.(ts|tsx)$' }

if(Test-Path -LiteralPath $rdc){
  $bk2 = BackupFile $rdc
  $t = Get-Content -LiteralPath $rdc -Raw
  $changed = $false

  if($t.Contains('export function GET(')){
    $t2 = $t.Replace('export function GET(', 'export async function GET(')
    if($t2 -ne $t){ $t = $t2; $changed = $true }
  }
  if($t.Contains('headers().get(')){
    $t2 = $t.Replace('headers().get(', '(await headers()).get(')
    if($t2 -ne $t){ $t = $t2; $changed = $true }
  }
  if($t.Contains(' = headers();')){
    $t2 = $t.Replace(' = headers();', ' = await headers();')
    if($t2 -ne $t){ $t = $t2; $changed = $true }
  }

  if($changed){
    WriteUtf8NoBom $rdc $t
    Write-Host ('OK: route-day-card ajustado p/ Next16 async headers -> ' + $rdc) -ForegroundColor Green
  } else {
    Write-Host ('INFO: route-day-card sem patch necessário (ou não usa headers()) -> ' + $rdc) -ForegroundColor Yellow
  }
} else {
  Write-Host 'INFO: não achei src/app/api/share/route-day-card/route.ts (skip)' -ForegroundColor Yellow
}

Write-Host '✅ HOTFIX 38g aplicado. Agora: CTRL+C ; npm run dev' -ForegroundColor Green