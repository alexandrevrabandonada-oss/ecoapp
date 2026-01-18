param([switch]$OpenReport)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$tools = Join-Path $root "tools"
$reports = Join-Path $root "reports"
$backupRoot = Join-Path $tools "_patch_backup"

function EnsureDir($p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom($p,$s){ [IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false)) }
function BackupFile($src,$tag){
  $safe = ($src -replace "[:\\\/]","_")
  $dstDir = Join-Path $backupRoot $tag
  EnsureDir $dstDir
  $dst = Join-Path $dstDir ((Get-Date).ToString("yyyyMMdd-HHmmss") + "-" + $safe)
  Copy-Item -Force $src $dst
  return $dst
}

EnsureDir $reports

$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$tag = "eco-step-184"
$reportPath = Join-Path $reports ("eco-step-184-fix-chamarcoleta-headers-" + $stamp + ".md")
$r = @()
$r += "# eco-step-184 — fix chamar-coleta headers (ecoAuthHeaders) — " + $stamp

$candidates = @(
  (Join-Path $root "src\app\chamar-coleta\page.tsx"),
  (Join-Path $root "src\app\chamar\page.tsx")
)
$target = $null
foreach($c in $candidates){ if(Test-Path $c){ $target = $c; break } }
if(-not $target){
  $r += "## DIAG"
  $r += "- nao achei src\app\chamar-coleta\page.tsx nem src\app\chamar\page.tsx"
  WriteUtf8NoBom $reportPath ($r -join "`n")
  throw "alvo nao encontrado"
}

$raw = Get-Content -Raw -Encoding UTF8 $target
$r += "## DIAG"
$r += "- alvo: " + ($target -replace [regex]::Escape($root.Path + "\"),"")
$r += "- contains ecoAuthHeaders(): " + ([bool]($raw -match "ecoAuthHeaders\s*\("))
$r += "- contains headers: ecoAuthHeaders(): " + ([bool]($raw -match "headers\s*:\s*ecoAuthHeaders\s*\(\s*\)"))

if($raw -notmatch "headers\s*:\s*ecoAuthHeaders\s*\(\s*\)"){
  $r += ""
  $r += "## PATCH"
  $r += "- nada a fazer: nao achei `headers: ecoAuthHeaders()` no arquivo"
  WriteUtf8NoBom $reportPath ($r -join "`n")
  Write-Host ("[REPORT] " + $reportPath)
  if($OpenReport){ Start-Process $reportPath | Out-Null }
  exit 0
}

$bak = BackupFile $target $tag
$lines2 = $raw -split "`n"

# acha a linha do fetch (inserir bloco imediatamente antes)
$insertAt = -1
for($i=0; $i -lt $lines2.Count; $i++){
  if($lines2[$i] -match "const\s+res\s*=\s*await\s+fetch\(" -and $lines2[$i] -match "pickup-requests"){ $insertAt = $i; break }
}
if($insertAt -lt 0){
  for($i=0; $i -lt $lines2.Count; $i++){
    if($lines2[$i] -match "fetch\(\s*['\""]/api/pickup-requests['\""]"){ $insertAt = $i; break }
  }
}
if($insertAt -lt 0){ throw "nao achei o fetch(/api/pickup-requests) para inserir bloco" }

# evita duplicar se rodar duas vezes
if($raw -notmatch "ECO_HEADERS_CLEAN_START"){
  $indent = ""
  if($lines2[$insertAt] -match "^(\s+)"){ $indent = $Matches[1] }
  $block = @()
  $block += ($indent + "// ECO_HEADERS_CLEAN_START")
  $block += ($indent + "const __ecoRawHeaders = (ecoAuthHeaders() as Record<string, unknown>) || {};")
  $block += ($indent + "const __ecoHeaders: Record<string, string> = {};")
  $block += ($indent + "for (const [k, v] of Object.entries(__ecoRawHeaders)) {")
  $block += ($indent + "  if (typeof v === ""string"" && v) __ecoHeaders[k] = v;")
  $block += ($indent + "}")
  $block += ($indent + "// ECO_HEADERS_CLEAN_END")
  $lines2 = @($lines2[0..($insertAt-1)] + $block + $lines2[$insertAt..($lines2.Count-1)])
}

# troca headers: ecoAuthHeaders() -> headers: __ecoHeaders
$raw2 = ($lines2 -join "`n")
$raw2 = [regex]::Replace($raw2, "headers\s*:\s*ecoAuthHeaders\s*\(\s*\)", "headers: __ecoHeaders")

WriteUtf8NoBom $target $raw2

$r += ""
$r += "## PATCH"
$r += "- backup: " + $bak
$r += "- inseriu bloco ECO_HEADERS_CLEAN_* antes do fetch"
$r += "- trocou headers: ecoAuthHeaders() -> headers: __ecoHeaders"

$r += "## VERIFY"
$r += "Rode:"
$r += "- npm run build"

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }