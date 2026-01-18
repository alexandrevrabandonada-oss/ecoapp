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
function GetLineIndent([string]$txt, [int]$idx){
  if($idx -lt 0){ return "" }
  $ls = $txt.LastIndexOf("`n", $idx)
  if($ls -lt 0){ $ls = 0 } else { $ls = $ls + 1 }
  $i = $ls
  $indent = ""
  while($i -lt $txt.Length){
    $ch = $txt[$i]
    if($ch -eq " " -or $ch -eq "`t"){
      $indent += $ch
      $i++
      continue
    }
    break
  }
  return $indent
}

$rep = NewReport "eco-step-18d-attach-receipt-in-pickup-list-by-include-safe"
$log = @()
$log += "# ECO — STEP 18d — Anexar receipt na lista de /api/pickup-requests (robusto)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG: localizar rota
# =========
$api = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $api)){
  $api = "app/api/pickup-requests/route.ts"
}
if(!(Test-Path -LiteralPath $api)){
  $api = FindFirst "src/app" "\\api\\pickup-requests\\route\.ts$"
}
if(!(Test-Path -LiteralPath $api)){
  $api = FindFirst "app" "\\api\\pickup-requests\\route\.ts$"
}
if(-not $api){ throw "Não achei /api/pickup-requests/route.ts (nem em src/app nem em app)" }

$log += "## DIAG"
$log += ("API pickup-requests: {0}" -f $api)
$log += ""

# =========
# PATCH (backup)
# =========
$log += "## PATCH"
$log += ("Backup API: {0}" -f (BackupFile $api))
$log += ""

$txt = Get-Content -LiteralPath $api -Raw

if($txt -match "ECO_STEP18_ATTACH_RECEIPT"){
  $log += "- INFO: marker ECO_STEP18_ATTACH_RECEIPT já existe (skip)."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 18d aplicado (skip). Report -> {0}" -f $rep) -ForegroundColor Green
  exit 0
}

# encontrar delegate.findMany(
$needle = "delegate.findMany("
$idx = $txt.IndexOf($needle)
if($idx -lt 0){
  # fallback mais tolerante
  $m = [regex]::Match($txt, "delegate\s*\.\s*findMany\s*\(")
  if($m.Success){ $idx = $m.Index } else { $idx = -1 }
}
if($idx -lt 0){
  throw "Não encontrei 'delegate.findMany(' em /api/pickup-requests. Não sei onde anexar receipt."
}

$indent = GetLineIndent $txt $idx

$snippetLines = @()
$snippetLines += ($indent + "// ECO_STEP18_ATTACH_RECEIPT")
$snippetLines += ($indent + "const _hasReceipt = !!((args as any)?.include?.receipt ?? (args as any)?.select?.receipt);")
$snippetLines += ($indent + "if (!_hasReceipt) {")
$snippetLines += ($indent + "  if ((args as any).select) {")
$snippetLines += ($indent + "    (args as any).select = { ...(args as any).select, receipt: true };")
$snippetLines += ($indent + "  } else {")
$snippetLines += ($indent + "    (args as any).include = { ...(((args as any).include) ?? {}), receipt: true };")
$snippetLines += ($indent + "  }")
$snippetLines += ($indent + "}")
$snippetLines += ($indent + "")

$snippet = ($snippetLines -join "`n")

# inserir snippet imediatamente antes do findMany
$before = $txt.Substring(0, $idx)
$after  = $txt.Substring($idx)
$txt2 = $before + $snippet + $after

WriteUtf8NoBom $api $txt2

$log += "- OK: /api/pickup-requests agora inclui receipt em items (via args.include/select), sem depender do formato do return."
$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /pedidos: itens fechados devem vir com receipt e mostrar 'Ver recibo'."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Remember: Write-Host ("✅ STEP 18d aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host ("✅ STEP 18d aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /pedidos -> deve aparecer 'Ver recibo' quando houver receipt" -ForegroundColor Yellow