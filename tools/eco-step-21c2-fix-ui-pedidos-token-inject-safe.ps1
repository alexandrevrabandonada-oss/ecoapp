$ErrorActionPreference = "Stop"

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
  EnsureDir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}
function FindFirst([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

function FindParenClose([string]$txt, [int]$openIdx){
  $depth = 0
  $inS = $false; $inD = $false; $inLC = $false; $inBC = $false
  for($i=$openIdx; $i -lt $txt.Length; $i++){
    $ch = $txt[$i]
    $n1 = if($i+1 -lt $txt.Length){ $txt[$i+1] } else { [char]0 }

    if($inLC){ if($ch -eq "`n"){ $inLC = $false }; continue }
    if($inBC){ if($ch -eq "*" -and $n1 -eq "/"){ $inBC=$false; $i++; }; continue }

    if($inS){
      if($ch -eq "\" -and $n1 -ne [char]0){ $i++; continue }
      if($ch -eq "'"){ $inS = $false }
      continue
    }
    if($inD){
      if($ch -eq "\" -and $n1 -ne [char]0){ $i++; continue }
      if($ch -eq '"'){ $inD = $false }
      continue
    }

    if($ch -eq "/" -and $n1 -eq "/"){ $inLC = $true; $i++; continue }
    if($ch -eq "/" -and $n1 -eq "*"){ $inBC = $true; $i++; continue }

    if($ch -eq "'"){ $inS = $true; continue }
    if($ch -eq '"'){ $inD = $true; continue }

    if($ch -eq "("){ $depth++; continue }
    if($ch -eq ")"){
      $depth--
      if($depth -eq 0){ return $i }
      continue
    }
  }
  return -1
}

$rep = NewReport "eco-step-21c2-fix-ui-pedidos-token-inject-safe"
$log = @()
$log += "# ECO — STEP 21c2 — Fix UI /pedidos token patch (sem crash)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# localizar UI file que faz fetch em /api/pickup-requests
$roots = @()
if(Test-Path -LiteralPath "src"){ $roots += "src" }
if(Test-Path -LiteralPath "app"){ $roots += "app" }
if($roots.Count -eq 0){ WriteUtf8NoBom $rep ($log -join "`n"); throw "Não achei src/ nem app/." }

$ui = $null
foreach($r in $roots){
  $files = Get-ChildItem -Recurse -File -Path $r -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @(".ts",".tsx",".js",".jsx") }
  foreach($f in $files){
    if($f.FullName -match "\\api\\pickup-requests\\route\.ts$"){ continue }
    $t = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if(!$t){ continue }
    if($t.Contains("/api/pickup-requests") -and $t.Contains("fetch")){
      $ui = $f.FullName
      break
    }
  }
  if($ui){ break }
}

$log += ("ui file: {0}" -f ($ui ? $ui : "(não achei)"))
$log += ""
if(-not $ui){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei arquivo de UI que faz fetch em /api/pickup-requests. Veja: $rep"
}

$txt = Get-Content -LiteralPath $ui -Raw
$log += ("Backup ui: {0}" -f (BackupFile $ui))

# (1) injeta helper de headers (se não existir)
if($txt -notmatch "ECO_STEP21C_PEDIDOS_TOKEN"){
  $helper = @"
`n// ECO_STEP21C_PEDIDOS_TOKEN
const ECO_TOKEN_KEY = "eco_operator_token";
function ecoReadToken() {
  if (typeof window === "undefined") return "";
  try { return localStorage.getItem(ECO_TOKEN_KEY) || ""; } catch { return ""; }
}
function ecoAuthHeaders() {
  const t = (ecoReadToken() || "").trim();
  return t ? { "x-eco-token": t } : {};
}
// ECO_STEP21C_PEDIDOS_TOKEN_END
"@
  $mImp = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
  if($mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
    $txt = $txt.Insert($insAt, $helper)
    $log += "- OK: helper ecoAuthHeaders injetado após imports."
  } else {
    $txt = $helper + "`n" + $txt
    $log += "- OK: helper ecoAuthHeaders injetado no topo."
  }
} else {
  $log += "- INFO: helper já existe (skip)."
}

# (2) patch do fetch('/api/pickup-requests') — procura por ocorrência do path e encontra fetch com clamp
$needle = "/api/pickup-requests"
$pos = 0
$patchedFetch = $false

while($true){
  $idx = $txt.IndexOf($needle, $pos)
  if($idx -lt 0){ break }

  $startSearch = [Math]::Max(0, $idx - 250)
  $sub = $txt.Substring($startSearch, $idx - $startSearch)
  $relFetch = $sub.LastIndexOf("fetch")
  if($relFetch -lt 0){
    $pos = $idx + $needle.Length
    continue
  }
  $idxFetch = $startSearch + $relFetch

  if($idxFetch -lt 0 -or $idxFetch -ge $txt.Length){
    $pos = $idx + $needle.Length
    continue
  }

  $idxOpen = $txt.IndexOf("(", $idxFetch)
  if($idxOpen -lt 0){
    $pos = $idx + $needle.Length
    continue
  }

  $idxClose = FindParenClose $txt $idxOpen
  if($idxClose -lt 0){
    $pos = $idx + $needle.Length
    continue
  }

  $inside = $txt.Substring($idxOpen+1, $idxClose-($idxOpen+1))

  if($inside -match "headers\s*:"){
    $log += "- INFO: fetch já tem headers (skip)."
    $patchedFetch = $true
    break
  }

  $comma = $inside.IndexOf(",")
  if($comma -ge 0){
    $after = $inside.Substring($comma+1)
    $b = $after.IndexOf("{")
    if($b -ge 0){
      $absB = ($idxOpen+1) + ($comma+1) + $b
      $txt = $txt.Substring(0, $absB+1) + "`n    headers: ecoAuthHeaders()," + $txt.Substring($absB+1)
      $log += "- OK: inseri headers: ecoAuthHeaders() no options."
      $patchedFetch = $true
      break
    } else {
      $txt = $txt.Substring(0, $idxClose) + ", { headers: ecoAuthHeaders() }" + $txt.Substring($idxClose)
      $log += "- WARN: não achei '{' no 2º arg; fallback -> adicionei { headers }."
      $patchedFetch = $true
      break
    }
  } else {
    $txt = $txt.Substring(0, $idxClose) + ", { headers: ecoAuthHeaders() }" + $txt.Substring($idxClose)
    $log += "- OK: fetch(url) -> fetch(url, { headers: ecoAuthHeaders() })."
    $patchedFetch = $true
    break
  }
}

if(-not $patchedFetch){
  $log += "- WARN: não consegui patchar nenhum fetch do /api/pickup-requests (pode estar diferente)."
}

WriteUtf8NoBom $ui $txt

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /pedidos: com token salvo em localStorage('eco_operator_token') deve mandar header x-eco-token"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 21c2 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /pedidos (com token) e aba anônima (sem token)" -ForegroundColor Yellow