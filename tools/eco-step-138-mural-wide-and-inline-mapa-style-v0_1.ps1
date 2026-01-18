$ErrorActionPreference = "Stop"

$stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
$root  = (Resolve-Path ".").Path
Write-Host ("== eco-step-138-mural-wide-and-inline-mapa-style-v0_1 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

# --- bootstrap (fallback safe) ---
$bootstrap = Join-Path $root "tools\_bootstrap.ps1"
if (Test-Path $bootstrap) { . $bootstrap }

function _EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ return }; if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function _WriteUtf8([string]$p,[string]$t){ _EnsureDir (Split-Path -Parent $p); [IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false)) }
function _Backup([string]$src,[string]$bd){ if(Test-Path $src){ _EnsureDir $bd; $name = ($src -replace "[:\\\\/]", "_") + ".bak"; Copy-Item -Force $src (Join-Path $bd $name) } }

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-138-" + $stamp)
_EnsureDir $backupDir

# ===== targets =====
$pagePath   = Join-Path $root "src\app\eco\mural\page.tsx"
$widePath   = Join-Path $root "src\app\eco\mural\_components\MuralWideStyles.tsx"
$inlinePath = Join-Path $root "src\app\eco\mural\_components\MuralInlineMapa.tsx"

Write-Host ("[DIAG] page.tsx: " + (Test-Path $pagePath))
Write-Host ("[DIAG] MuralInlineMapa.tsx: " + (Test-Path $inlinePath))

# ===== PATCH 1: create/update MuralWideStyles.tsx =====
_Backup $widePath $backupDir
_EnsureDir (Split-Path -Parent $widePath)

$wideLines = @(
  "import React from ""react"";",
  "",
  "export default function MuralWideStyles() {",
  "  const css = [",
  "    ""/* ECO — Mural Wide + Mapa Inline */"",",
  "    ""/* ativa em qualquer wrapper que tenha eco-mural + data-eco-wide=''1'' */"",",
  "    "".eco-mural[data-eco-wide=''1''] { max-width: none !important; width: min(1700px, calc(100% - 32px)) !important; margin: 0 auto !important; }"",",
  "    "".eco-mural[data-eco-wide=''1''] { padding-left: 0 !important; padding-right: 0 !important; }"",",
  "    ""@media (min-width: 900px) { .eco-mural[data-eco-wide=''1''] { width: min(1700px, calc(100% - 48px)) !important; } }"",",
  "    """,",
  "    ""/* mapa inline (iframe) */"",",
  "    "".eco-mural__map { margin-top: 14px !important; }"",",
  "    "".eco-mural__mapIframe { width: 100% !important; height: 440px !important; border: 1px solid rgba(0,0,0,.25) !important; border-radius: 12px !important; overflow: hidden !important; background: #e9e9e9 !important; }"",",
  "    ""@media (min-width: 1100px) { .eco-mural__mapIframe { height: 560px !important; } }"",",
  "  ].join(""\\n"");",
  "  return <style dangerouslySetInnerHTML={{ __html: css }} />;",
  "}",
)

$wideContent = ($wideLines -join "`n")
_WriteUtf8 $widePath $wideContent
Write-Host ("[PATCH] updated -> " + $widePath) -ForegroundColor Green

# ===== PATCH 2: page.tsx import + render + data-eco-wide =====
if (!(Test-Path $pagePath)) { throw ("Missing: " + $pagePath) }
_Backup $pagePath $backupDir
$raw = Get-Content -Raw $pagePath
$orig = $raw

$importLine = "import MuralWideStyles from ""./_components/MuralWideStyles"";"
if ($raw -notmatch [regex]::Escape($importLine)) {
  # inserir após o último import no topo
  $lines = $raw -split "`r?`n"
  $lastImport = -1
  for($i=0;$i -lt $lines.Length;$i++){ if($lines[$i] -match "^\s*import\s+"){ $lastImport = $i } }
  if($lastImport -ge 0){
    $pre  = $lines[0..$lastImport]
    $post = @()
    if($lastImport+1 -lt $lines.Length){ $post = $lines[($lastImport+1)..($lines.Length-1)] }
    $lines = @($pre + @($importLine) + $post)
    $raw = ($lines -join "`n")
    Write-Host "[PATCH] page.tsx import: OK" -ForegroundColor Green
  } else {
    $raw = $importLine + "`n" + $raw
    Write-Host "[PATCH] page.tsx import: inserted top" -ForegroundColor Yellow
  }
} else {
  Write-Host "[PATCH] page.tsx import: already" -ForegroundColor DarkGray
}

if ($raw -notmatch "<MuralWideStyles\\s*/>") {
  if ($raw -match "<MuralReadableStyles\\s*/>") {
    $raw = [regex]::Replace($raw, "<MuralReadableStyles\\s*/>", "$0`n      <MuralWideStyles />", 1)
    Write-Host "[PATCH] page.tsx render: after MuralReadableStyles" -ForegroundColor Green
  } elseif ($raw -match "return\\s*\\(\\s*<>") {
    $raw = [regex]::Replace($raw, "return\\s*\\(\\s*<>", "return (`n    <>`n      <MuralWideStyles />", 1)
    Write-Host "[PATCH] page.tsx render: fragment head" -ForegroundColor Green
  } else {
    # fallback: tenta colocar logo após a primeira tag retornada
    $raw = [regex]::Replace($raw, "return\\s*\\(\\s*<", "return (`n    <`n      <MuralWideStyles />`n      <", 1)
    Write-Host "[PATCH] page.tsx render: fallback insert (check JSX)" -ForegroundColor Yellow
  }
} else {
  Write-Host "[PATCH] page.tsx render: already" -ForegroundColor DarkGray
}

if ($raw -notmatch "data-eco-wide=") {
  # injeta data-eco-wide="1" logo depois do primeiro className que contenha eco-mural
  $rx = [regex]::new("className=""[^""]*\\beco-mural\\b[^""]*""")
  $m = $rx.Match($raw)
  if ($m.Success) {
    $raw = $raw.Substring(0, $m.Index + $m.Length) + " data-eco-wide=""1""" + $raw.Substring($m.Index + $m.Length)
    Write-Host "[PATCH] page.tsx data-eco-wide: OK" -ForegroundColor Green
  } else {
    Write-Host "[PATCH] page.tsx data-eco-wide: eco-mural class not found (skipped)" -ForegroundColor Yellow
  }
} else {
  Write-Host "[PATCH] page.tsx data-eco-wide: already" -ForegroundColor DarkGray
}

if ($raw -ne $orig) { _WriteUtf8 $pagePath $raw }

# ===== PATCH 3: MuralInlineMapa.tsx (ancora + classes no iframe) =====
if (Test-Path $inlinePath) {
  _Backup $inlinePath $backupDir
  $im = Get-Content -Raw $inlinePath
  $imOrig = $im

  # 3.1: garantir id="mural-mapa" e class eco-mural__map no primeiro <section> (ou <div> se não tiver)
  $tagName = ""
  if ($im -match "<section\\b") { $tagName = "section" } elseif ($im -match "<div\\b") { $tagName = "div" }
  if ($tagName -ne "") {
    $open = "<" + $tagName
    $idx = $im.IndexOf($open)
    if ($idx -ge 0) {
      $end = $im.IndexOf(">", $idx)
      if ($end -gt $idx) {
        $tag = $im.Substring($idx, $end-$idx+1)
        $newTag = $tag
        if ($newTag -notmatch "id=""mural-mapa""") {
          if ($newTag -match ("<" + $tagName + "\\s")) {
            $newTag = $newTag -replace ("<" + $tagName + "\\s"), ("<" + $tagName + " id=""mural-mapa"" ")
          } else {
            $newTag = $newTag -replace ("<" + $tagName), ("<" + $tagName + " id=""mural-mapa""")
          }
        }
        if ($newTag -match "className=""([^""]*)""") {
          $cls = $Matches[1]
          if ($cls -notmatch "\\beco-mural__map\\b") {
            $cls2 = ($cls + " eco-mural__map").Trim()
            $newTag = $newTag -replace "className=""[^""]*""", ("className=""" + $cls2 + """")
          }
        } else {
          # inserir className antes do >
          $newTag = $newTag.Substring(0, $newTag.Length-1) + " className=""eco-mural__map"">"
        }
        if ($newTag -ne $tag) {
          $im = $im.Substring(0,$idx) + $newTag + $im.Substring($end+1)
        }
      }
    }
  }

  # 3.2: garantir className eco-mural__mapIframe no primeiro <iframe
  if ($im -match "<iframe\\b") {
    $i0 = $im.IndexOf("<iframe")
    $i1 = $im.IndexOf(">", $i0)
    if ($i0 -ge 0 -and $i1 -gt $i0) {
      $itag = $im.Substring($i0, $i1-$i0+1)
      $newItag = $itag
      if ($newItag -match "className=""([^""]*)""") {
        $c = $Matches[1]
        if ($c -notmatch "\\beco-mural__mapIframe\\b") {
          $c2 = ($c + " eco-mural__mapIframe").Trim()
          $newItag = $newItag -replace "className=""[^""]*""", ("className=""" + $c2 + """")
        }
      } else {
        $newItag = $newItag -replace "<iframe\\s", "<iframe className=""eco-mural__mapIframe"" "
      }
      if ($newItag -ne $itag) {
        $im = $im.Substring(0,$i0) + $newItag + $im.Substring($i1+1)
      }
    }
  }

  if ($im -ne $imOrig) {
    _WriteUtf8 $inlinePath $im
    Write-Host ("[PATCH] updated -> " + $inlinePath) -ForegroundColor Green
  } else {
    Write-Host "[PATCH] inline mapa: no changes (already styled?)" -ForegroundColor DarkGray
  }
} else {
  Write-Host "[PATCH] inline mapa: missing file (skip) -> MuralInlineMapa.tsx" -ForegroundColor Yellow
}

# ===== REPORT =====
$reportDir = Join-Path $root "reports"
_EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-138-mural-wide-and-inline-mapa-style-" + $stamp + ".md")
$r = @()
$r += ("# eco-step-138-mural-wide-and-inline-mapa-style-v0_1 - " + $stamp)
$r += ""
$r += "## PATCH"
$r += ("- updated: " + $widePath)
$r += ("- updated: " + $pagePath)
if (Test-Path $inlinePath) { $r += ("- updated: " + $inlinePath) }
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir /eco/mural (deve ficar mais largo)"
$r += "- /eco/mural?map=1&focus=<id> (iframe maior + ancora id=mural-mapa)"
$r += ""
_WriteUtf8 $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor Yellow

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Cyan
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  testar /eco/mural?map=1&focus=<id>"