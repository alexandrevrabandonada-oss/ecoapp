param([switch]$OpenReport)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path
Write-Host ("== eco-step-140c-fix-mural-page-mapopen-and-split-clean-v0_1 == " + $stamp) -ForegroundColor Cyan

function EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}
function WriteUtf8NoBom([string]$path, [string]$content) {
  if ([string]::IsNullOrWhiteSpace($path)) { throw "WriteUtf8NoBom: path vazio" }
  $parent = Split-Path -Parent $path
  if (-not [string]::IsNullOrWhiteSpace($parent)) { EnsureDir $parent }
  [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$src, [string]$backupDir) {
  EnsureDir $backupDir
  if (-not (Test-Path -LiteralPath $src)) { throw ("BackupFile: nao achei " + $src) }
  $leaf = Split-Path -Leaf $src
  Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir ($leaf + ".bak")) -Force
}

$pagePath = Join-Path $root "src\app\eco\mural\page.tsx"
if (-not (Test-Path -LiteralPath $pagePath)) { throw ("Nao achei: " + $pagePath) }

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-140c-fix-mural-page-mapopen-and-split-clean-v0_1-" + $stamp)
EnsureDir $backupDir
BackupFile $pagePath $backupDir

$raw = [System.IO.File]::ReadAllText($pagePath, [System.Text.UTF8Encoding]::new($false))

# normaliza operadores do PowerShell que podem ter vazado pro TS/JS
$raw = $raw -replace "\s+-or\s+", " || " -replace "\s+-and\s+", " && "

# garante Page recebendo searchParams (App Router)
if ($raw -match "export default function Page\(\)") {
  $raw = $raw -replace "export default function Page\(\)", "export default function Page({ searchParams }: { searchParams?: Record<string, string | string[]> })"
}

# bloco robusto de mapOpen
$mapBlockLines = @(
  '  const mapRaw = searchParams?.map;',
  '  const mapVal = Array.isArray(mapRaw) ? mapRaw[0] : mapRaw;',
  '  const mapOpen = (mapVal === "1" || mapVal === "true");'
)
$mapBlock = ($mapBlockLines -join "`n")

if ($raw -match "(?m)^\s*const mapOpen\s*=.*$") {
  $raw = [regex]::Replace($raw, "(?m)^\s*const mapOpen\s*=.*$", $mapBlock)
} elseif ($raw -notmatch "const mapOpen") {
  $lines0 = $raw -split "`r?`n"
  $out0 = New-Object System.Collections.Generic.List[string]
  $inserted = $false
  $pending = $false
  foreach ($ln0 in $lines0) {
    $out0.Add($ln0)
    if (-not $inserted -and $ln0 -match "export default function Page") {
      if ($ln0 -match "\{") {
        $out0.AddRange($mapBlockLines)
        $inserted = $true
      } else {
        $pending = $true
      }
      continue
    }
    if ($pending -and -not $inserted -and $ln0 -match "\{") {
      $out0.AddRange($mapBlockLines)
      $inserted = $true
      $pending = $false
      continue
    }
  }
  $raw = ($out0.ToArray() -join "`n")
}

# garante data-map no <main className="eco-mural"...>
if (($raw -match "<main") -and ($raw -match "className=`"eco-mural`"") -and ($raw -notmatch "data-map=")) {
  $raw = [regex]::Replace($raw, "<main([^>]*className=`"eco-mural`"[^>]*)>", "<main$1 data-map={mapOpen ? `"1`" : `"0`"}>")
}

# rebuild do split: remove wrappers quebrados e recria em volta do MuralInlineMapa
$lines = $raw -split "`r?`n"
$out = New-Object System.Collections.Generic.List[string]
$openedSplit = $false
$openedRight = $false
$closedSplit = $false
$skipClose = 0

function IsWrapperLine([string]$l) {
  return ($l -match "eco-mural-split" -or $l -match "eco-mural-left" -or $l -match "eco-mural-right" -or $l -match "eco-mural-map")
}

foreach ($ln in $lines) {
  $t = $ln.Trim()

  if ($skipClose -gt 0) {
    if ($t -eq "</div>" -or $t -eq "</aside>" -or $t -eq "") { $skipClose--; continue }
    $skipClose = 0
  }

  if (IsWrapperLine $ln) { continue }
  if ($t -eq "</aside>") { continue }

  $isStyleAnchor = (-not $openedSplit) -and ($ln -match "<MuralWideStyles" -or $ln -match "<EcoWideStyles" -or $ln -match "<EcoWideShell")
  if ($isStyleAnchor) {
    $out.Add($ln)
    $out.Add("      <div className=`"eco-mural-split`">")
    $out.Add("        <div className=`"eco-mural-left`">")
    $openedSplit = $true
    continue
  }

  if ($ln -match "<MuralInlineMapa") {
    if (-not $openedSplit) {
      $out.Add("      <div className=`"eco-mural-split`">")
      $out.Add("        <div className=`"eco-mural-left`">")
      $out.Add("        </div>")
      $out.Add("        <div className=`"eco-mural-right`">")
      $openedSplit = $true
      $openedRight = $true
    } elseif (-not $openedRight) {
      if ($out.Count -gt 0 -and $out[$out.Count-1].Trim() -eq "</div>") { $out.RemoveAt($out.Count-1) }
      $out.Add("        </div>")
      $out.Add("        <div className=`"eco-mural-right`">")
      $openedRight = $true
    }

    $out.Add($ln)
    $out.Add("        </div>")
    $out.Add("      </div>")
    $closedSplit = $true
    $skipClose = 8
    continue
  }

  $out.Add($ln)
}

if ($openedSplit -and -not $closedSplit) { throw "Nao encontrei <MuralInlineMapa /> para fechar o split. Abortando." }

$patched = ($out.ToArray() -join "`n")
WriteUtf8NoBom $pagePath $patched
Write-Host ("[PATCH] fixed -> " + $pagePath) -ForegroundColor Green

# report
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-140c-fix-mural-page-mapopen-and-split-clean-v0_1-" + $stamp + ".md")
$r = @()
$r += "# eco-step-140c-fix-mural-page-mapopen-and-split-clean-v0_1 - $stamp"
$r += ""
$r += ("Backup: " + $backupDir)
$r += ""
$r += "Patch:"
$r += "- page.tsx: Page props + mapOpen + data-map + rebuild split wrappers"
$r += ""
$r += "Verify:"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir /eco/mural"
$r += "- abrir /eco/mural?map=1 (desktop: 2 colunas + mapa sticky a direita)"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if ($OpenReport) { Start-Process $reportPath | Out-Null }