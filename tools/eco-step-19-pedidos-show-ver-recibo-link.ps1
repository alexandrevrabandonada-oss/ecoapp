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

function FindFileContaining([string]$root, [string]$needle){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $files = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @(".ts",".tsx",".js",".jsx") }

  foreach($f in $files){
    $t = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if($t -and $t.Contains($needle)){
      return $f.FullName
    }
  }
  return $null
}

function DetectMapVar([string]$txt, [int]$idx){
  # tenta achar ".map((it" mais próximo antes do idx
  $winStart = [Math]::Max(0, $idx - 2000)
  $win = $txt.Substring($winStart, $idx - $winStart)

  $m = [regex]::Match($win, "map\s*\(\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)", "RightToLeft")
  if($m.Success){ return $m.Groups[1].Value }
  return "item"
}

$rep = NewReport "eco-step-19-pedidos-show-ver-recibo-link"
$log = @()
$log += "# ECO — STEP 19 — /pedidos: mostrar 'Ver recibo' quando houver receipt"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG: achar arquivo do /pedidos list
# =========
$roots = @()
if(Test-Path -LiteralPath "src"){ $roots += "src" }
if(Test-Path -LiteralPath "app"){ $roots += "app" }
if($roots.Count -eq 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei pasta src/ nem app/."
}

$pedidosFile = $null
foreach($r in $roots){
  $pedidosFile = FindFileContaining $r "Fechar / Emitir recibo"
  if($pedidosFile){ break }
}
if(-not $pedidosFile){
  foreach($r in $roots){
    $pedidosFile = FindFileContaining $r "/pedidos/fechar"
    if($pedidosFile){ break }
  }
}
if(-not $pedidosFile){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei o arquivo do /pedidos (procurei por 'Fechar / Emitir recibo' e '/pedidos/fechar'). Veja: $rep"
}

$log += "## DIAG"
$log += ("arquivo: {0}" -f $pedidosFile)
$log += ""

$txt = Get-Content -LiteralPath $pedidosFile -Raw

if($txt.Contains("Ver recibo") -and $txt.Contains("receiptCodeFromItem")){
  $log += "- INFO: Parece que o /pedidos já tem 'Ver recibo' + helper. Skip."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 19 (skip) — já aplicado. Report -> {0}" -f $rep) -ForegroundColor Yellow
  exit 0
}

$log += "## PATCH"
$log += ("Backup: {0}" -f (BackupFile $pedidosFile))

# =========
# PATCH 1: garantir import do Link
# =========
if(-not $txt.Contains('from "next/link"') -and -not $txt.Contains("from 'next/link'")){
  # insere após "use client"; ou topo
  $uc = '"use client";'
  $pos = $txt.IndexOf($uc)
  if($pos -ge 0){
    $insertAt = $pos + $uc.Length
    $ins = "`n`nimport Link from `"next/link`";"
    $txt = $txt.Insert($insertAt, $ins)
    $log += "- OK: import Link adicionado."
  } else {
    $txt = "import Link from `"next/link`";`n" + $txt
    $log += "- OK: import Link adicionado no topo."
  }
} else {
  $log += "- INFO: import Link já existe."
}

# =========
# PATCH 2: inserir helper receiptCodeFromItem após imports
# (sem template string, sem $)
# =========
if(-not $txt.Contains("function receiptCodeFromItem")){
  $helperLines = @()
  $helperLines += ""
  $helperLines += "// ECO_STEP19_RECEIPT_HELPER"
  $helperLines += "function receiptCodeFromItem(it: any) {"
  $helperLines += "  const r ="
  $helperLines += "    it?.receipt ??"
  $helperLines += "    it?.recibo ??"
  $helperLines += "    it?.Receipt ??"
  $helperLines += "    it?.receiptData ??"
  $helperLines += "    it?.receiptRef ??"
  $helperLines += "    null;"
  $helperLines += ""
  $helperLines += "  const code ="
  $helperLines += "    r?.shareCode ?? r?.code ?? r?.id ?? it?.receiptCode ?? it?.receiptId ?? null;"
  $helperLines += ""
  $helperLines += "  return typeof code === `"string`" ? code : null;"
  $helperLines += "}"
  $helperLines += ""

  $helper = ($helperLines -join "`n")

  $mImp = [regex]::Matches($txt, "^\s*import\s+.*?;\s*$", "Multiline")
  if($mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
    $txt = $txt.Insert($insAt, "`n" + $helper)
    $log += "- OK: helper receiptCodeFromItem inserido após imports."
  } else {
    $txt = $helper + "`n" + $txt
    $log += "- OK: helper receiptCodeFromItem inserido no topo."
  }
} else {
  $log += "- INFO: helper já existe."
}

# =========
# PATCH 3: inserir "Ver recibo" após o link "Fechar / Emitir recibo"
# =========
$idx = $txt.IndexOf("Fechar / Emitir recibo")
if($idx -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei o texto 'Fechar / Emitir recibo' no arquivo para aplicar o patch UI."
}

$itVar = DetectMapVar $txt $idx
$log += ("- INFO: var detectada no map: {0}" -f $itVar)

# localizar o fechamento </Link> depois do texto
$after = $txt.IndexOf("</Link>", $idx)
if($after -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei '</Link>' após 'Fechar / Emitir recibo' — não sei onde inserir o 'Ver recibo'."
}

$snippetLines = @()
$snippetLines += ""
$snippetLines += "{(() => {"
$snippetLines += "  const __c = receiptCodeFromItem(" + $itVar + ");"
$snippetLines += "  return __c ? ("
$snippetLines += "    <>"
$snippetLines += "      <span className=`"mx-2 opacity-60`">•</span>"
$snippetLines += "      <Link className=`"underline`" href={`"/recibo/`" + __c}>Ver recibo</Link>"
$snippetLines += "    </>"
$snippetLines += "  ) : null;"
$snippetLines += "})()}"
$snippetLines += ""

$snippet = ($snippetLines -join "`n")

# insere logo após o </Link> do Fechar
$insertPos = $after + 7
$txt = $txt.Insert($insertPos, $snippet)
$log += "- OK: inserido link 'Ver recibo' condicional após 'Fechar / Emitir recibo'."

WriteUtf8NoBom $pedidosFile $txt

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /pedidos: se a linha tiver receipt, deve aparecer 'Ver recibo'."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 19 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /pedidos -> aparece 'Ver recibo' quando houver" -ForegroundColor Yellow