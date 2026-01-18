$ErrorActionPreference = "Stop"

$stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
$root  = (Resolve-Path ".").Path
Write-Host ("== eco-step-138b-mural-wide-and-inline-mapa-style-safe-v0_2 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ return }; if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path,[string]$content){ $dir = Split-Path -Parent $path; if(-not [string]::IsNullOrWhiteSpace($dir)){ EnsureDir $dir }; [IO.File]::WriteAllText($path,$content,[Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$src,[string]$backupDir){ if(Test-Path $src){ EnsureDir $backupDir; $name = ($src -replace "[:\\\\/]", "_") + ".bak"; Copy-Item -Force $src (Join-Path $backupDir $name) } }

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-138b-" + $stamp)
EnsureDir $backupDir

$pagePath   = Join-Path $root "src\app\eco\mural\page.tsx"
$widePath   = Join-Path $root "src\app\eco\mural\_components\MuralWideStyles.tsx"
$inlinePath = Join-Path $root "src\app\eco\mural\_components\MuralInlineMapa.tsx"

Write-Host ("[DIAG] page.tsx exists: " + (Test-Path $pagePath))
Write-Host ("[DIAG] inline mapa exists: " + (Test-Path $inlinePath))

# ===== 1) criar/atualizar MuralWideStyles.tsx =====
BackupFile $widePath $backupDir
$wideTs = @'
import React from "react";

export default function MuralWideStyles() {
  const css = `
    /* ECO — Mural Wide + Mapa Inline */
    .eco-mural {
      max-width: none !important;
      width: min(1700px, calc(100% - 32px)) !important;
      margin: 0 auto !important;
      padding-left: 0 !important;
      padding-right: 0 !important;
    }
    @media (min-width: 900px) {
      .eco-mural {
        width: min(1700px, calc(100% - 48px)) !important;
      }
    }

    /* mapa inline (iframe) */
    .eco-mural__map {
      margin-top: 14px !important;
    }
    .eco-mural__mapIframe {
      width: 100% !important;
      height: 440px !important;
      border: 1px solid rgba(0,0,0,.25) !important;
      border-radius: 12px !important;
      overflow: hidden !important;
      background: #e9e9e9 !important;
    }
    @media (min-width: 1100px) {
      .eco-mural__mapIframe {
        height: 560px !important;
      }
    }
  `;

  return <style dangerouslySetInnerHTML={{ __html: css }} />;
}
'@
WriteUtf8NoBom $widePath $wideTs
Write-Host ("[PATCH] updated -> " + $widePath) -ForegroundColor Green

# ===== 2) patch page.tsx (import + render) =====
if (!(Test-Path $pagePath)) { throw ("Missing: " + $pagePath) }
BackupFile $pagePath $backupDir
$raw = Get-Content -Raw $pagePath
$orig = $raw

$importLine = "import MuralWideStyles from ""./_components/MuralWideStyles"";"
if ($raw -notmatch [regex]::Escape($importLine)) {
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

if ($raw -notmatch "<MuralWideStyles\s*/>") {
  if ($raw -match "<MuralReadableStyles\s*/>") {
    $raw = [regex]::Replace($raw, "<MuralReadableStyles\s*/>", "$0`n      <MuralWideStyles />", 1)
    Write-Host "[PATCH] page.tsx render: after MuralReadableStyles" -ForegroundColor Green
  } elseif ($raw -match "return\s*\(\s*<>") {
    $raw = [regex]::Replace($raw, "return\s*\(\s*<>", "return (`n    <>`n      <MuralWideStyles />", 1)
    Write-Host "[PATCH] page.tsx render: fragment head" -ForegroundColor Green
  } else {
    Write-Host "[PATCH] page.tsx render: could not place safely (skipped)" -ForegroundColor Yellow
  }
} else {
  Write-Host "[PATCH] page.tsx render: already" -ForegroundColor DarkGray
}

if ($raw -ne $orig) { WriteUtf8NoBom $pagePath $raw }

# ===== 3) patch MuralInlineMapa.tsx (ancora + class no iframe) =====
if (Test-Path $inlinePath) {
  BackupFile $inlinePath $backupDir
  $im = Get-Content -Raw $inlinePath
  $imOrig = $im

  # 3.1: primeira <section ...> ou <div ...> vira id="mural-mapa" + class eco-mural__map
  $tagName = ""
  if ($im -match "<section\b") { $tagName = "section" } elseif ($im -match "<div\b") { $tagName = "div" }
  if ($tagName -ne "") {
    $open = "<" + $tagName
    $i0 = $im.IndexOf($open)
    if ($i0 -ge 0) {
      $i1 = $im.IndexOf(">", $i0)
      if ($i1 -gt $i0) {
        $tag = $im.Substring($i0, $i1-$i0+1)
        $newTag = $tag
        if ($newTag -notmatch "id=""mural-mapa""") {
          $newTag = $newTag -replace ("<" + $tagName + "\s"), ("<" + $tagName + " id=""mural-mapa"" ")
        }
        if ($newTag -match "className=""([^""]*)""") {
          $cls = $Matches[1]
          if ($cls -notmatch "\beco-mural__map\b") {
            $cls2 = ($cls + " eco-mural__map").Trim()
            $newTag = $newTag -replace "className=""[^""]*""", ("className=""" + $cls2 + """")
          }
        } else {
          $newTag = $newTag.Substring(0, $newTag.Length-1) + " className=""eco-mural__map"">"
        }
        if ($newTag -ne $tag) {
          $im = $im.Substring(0,$i0) + $newTag + $im.Substring($i1+1)
        }
      }
    }
  }

  # 3.2: primeiro <iframe ...> ganha className eco-mural__mapIframe
  $ii0 = $im.IndexOf("<iframe")
  if ($ii0 -ge 0) {
    $ii1 = $im.IndexOf(">", $ii0)
    if ($ii1 -gt $ii0) {
      $itag = $im.Substring($ii0, $ii1-$ii0+1)
      $newItag = $itag
      if ($newItag -match "className=""([^""]*)""") {
        $c = $Matches[1]
        if ($c -notmatch "\beco-mural__mapIframe\b") {
          $c2 = ($c + " eco-mural__mapIframe").Trim()
          $newItag = $newItag -replace "className=""[^""]*""", ("className=""" + $c2 + """")
        }
      } else {
        $newItag = $newItag -replace "<iframe\s", "<iframe className=""eco-mural__mapIframe"" "
      }
      if ($newItag -ne $itag) {
        $im = $im.Substring(0,$ii0) + $newItag + $im.Substring($ii1+1)
      }
    }
  }

  if ($im -ne $imOrig) {
    WriteUtf8NoBom $inlinePath $im
    Write-Host ("[PATCH] updated -> " + $inlinePath) -ForegroundColor Green
  } else {
    Write-Host "[PATCH] inline mapa: no changes" -ForegroundColor DarkGray
  }
} else {
  Write-Host "[PATCH] inline mapa: missing (skip)" -ForegroundColor Yellow
}

# ===== REPORT =====
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-138b-mural-wide-and-inline-mapa-style-safe-" + $stamp + ".md")
$r = @()
$r += ("# eco-step-138b-mural-wide-and-inline-mapa-style-safe-v0_2 - " + $stamp)
$r += ""
$r += "## PATCH"
$r += ("- updated: " + $widePath)
$r += ("- updated: " + $pagePath)
if (Test-Path $inlinePath) { $r += ("- updated: " + $inlinePath) }
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir /eco/mural (deve ficar mais largo)"
$r += "- abrir /eco/mural?map=1&focus=<id> (iframe maior + ancora #mural-mapa)"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor Yellow

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Cyan
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  abrir /eco/mural?map=1&focus=<id>"