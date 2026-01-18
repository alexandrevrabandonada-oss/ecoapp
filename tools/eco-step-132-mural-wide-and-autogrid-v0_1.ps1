# eco-step-132-mural-wide-and-autogrid-v0_1
$ErrorActionPreference = "Stop"
$me = "eco-step-132-mural-wide-and-autogrid-v0_1"
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")

# Root = pasta do repo (pai de /tools)
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $Root
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

# --- bootstrap (tenta usar tools/_bootstrap.ps1; se falhar, fallback local) ---
$bootstrap = Join-Path $Root "tools\_bootstrap.ps1"
$bootOk = $false
if (Test-Path -LiteralPath $bootstrap) {
  try {
    . $bootstrap
    if (Get-Command EnsureDir -ErrorAction SilentlyContinue) { $bootOk = $true }
  } catch {
    $bootOk = $false
  }
}

if (-not $bootOk) {
  function EnsureDir([string]$p) {
    if ([string]::IsNullOrWhiteSpace($p)) { return }
    if (!(Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
  }
  function WriteUtf8NoBom([string]$p, [string]$content) {
    EnsureDir (Split-Path -Parent $p)
    [System.IO.File]::WriteAllText($p, $content, [System.Text.UTF8Encoding]::new($false))
  }
  function BackupFile([string]$src, [string]$backupDir) {
    if (Test-Path -LiteralPath $src) {
      EnsureDir $backupDir
      $leaf = Split-Path -Leaf $src
      Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir $leaf) -Force
    }
  }
}

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

function PatchRewrite([string]$relPath, [string[]]$lines) {
  $full = Join-Path $Root $relPath
  if (!(Test-Path -LiteralPath $full)) {
    Write-Host ("[SKIP] missing -> " + $relPath)
    return $false
  }
  BackupFile $full $backupDir
  WriteUtf8NoBom $full ($lines -join "`n")
  Write-Host ("[PATCH] rewrote -> " + $relPath)
  return $true
}

function PatchReplace([string]$relPath, [string]$find, [string]$repl) {
  $full = Join-Path $Root $relPath
  if (!(Test-Path -LiteralPath $full)) { return $false }
  $raw = Get-Content -Raw -LiteralPath $full
  if ($null -eq $raw) { return $false }
  if ($raw.IndexOf($find) -lt 0) { return $false }
  BackupFile $full $backupDir
  $raw2 = $raw.Replace($find, $repl)
  WriteUtf8NoBom $full $raw2
  Write-Host ("[PATCH] replace in -> " + $relPath)
  return $true
}

function EnsureInnerWrap([string]$relPath) {
  $full = Join-Path $Root $relPath
  if (!(Test-Path -LiteralPath $full)) { return $false }
  $raw = Get-Content -Raw -LiteralPath $full
  if ($null -eq $raw) { return $false }
  if ($raw -match "eco-mural-inner") { return $true }

  $iMain = $raw.IndexOf("<main")
  if ($iMain -lt 0) { return $false }
  $iGt = $raw.IndexOf(">", $iMain)
  if ($iGt -lt 0) { return $false }
  $iClose = $raw.LastIndexOf("</main>")
  if ($iClose -lt 0) { return $false }

  $open = "`n      <div className=""eco-mural-inner"">"
  $close = "`n      </div>`n"

  BackupFile $full $backupDir
  $raw2 = $raw.Insert($iGt + 1, $open)
  $raw2 = $raw2.Insert($iClose + $open.Length, $close)
  WriteUtf8NoBom $full $raw2
  Write-Host ("[PATCH] wrapped inner -> " + $relPath)
  return $true
}

# 1) Reescreve estilos do modo legível (mais largo + container interno)
$styles = @(
'// MuralReadableStyles.tsx (auto) — escopo: .eco-mural',
'',
'const css =',
'  ".eco-mural { background: transparent !important; color: #111 !important; min-height: 100vh !important; padding: 18px 0 32px !important; }\\n" +',
'  ".eco-mural .eco-mural-inner { width: min(1100px, calc(100% - 24px)); margin: 0 auto; background: #f6f6f6 !important; border: 2px solid #111 !important; border-radius: 16px !important; padding: 16px !important; }\\n" +',
'  ".eco-mural h1 { font-size: 26px !important; line-height: 1.15 !important; color: #111 !important; }\\n" +',
'  ".eco-mural h2 { font-size: 18px !important; line-height: 1.2 !important; color: #111 !important; }\\n" +',
'  ".eco-mural p, .eco-mural span, .eco-mural div { color: #111 !important; }\\n" +',
'  ".eco-mural a { color: #111 !important; font-weight: 900 !important; text-decoration: underline !important; }\\n" +',
'  ".eco-mural button { font-size: 14px !important; font-weight: 900 !important; border: 2px solid #111 !important; border-radius: 12px !important; background: #fff !important; padding: 8px 10px !important; }\\n" +',
'  ".eco-mural input, .eco-mural select, .eco-mural textarea { background: #fff !important; color: #111 !important; border: 2px solid #111 !important; border-radius: 12px !important; padding: 10px !important; font-size: 14px !important; }\\n" +',
'  ".eco-mural hr { border: 0 !important; border-top: 2px solid #111 !important; opacity: 0.2 !important; }\\n" +',
'  ".eco-mural .eco-pill { border: 2px solid #111 !important; border-radius: 999px !important; padding: 6px 10px !important; background: #fff !important; font-weight: 900 !important; }\\n";',
'',
'export default function MuralReadableStyles() {',
'  return <style>{css}</style>;',
'}',
''
)

PatchRewrite "src\app\eco\mural\_components\MuralReadableStyles.tsx" $styles | Out-Null

# 2) Garante wrapper interno (mais largo) no /eco/mural
EnsureInnerWrap "src\app\eco\mural\page.tsx" | Out-Null

# 3) Se existir /eco/mural-acoes, também aplica wrapper interno
EnsureInnerWrap "src\app\eco\mural-acoes\page.tsx" | Out-Null

# 4) Grid do topo: auto-fit (se achar o padrão)
$autoFit = 'gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))"'
PatchReplace "src\app\eco\mural\MuralClient.tsx" 'gridTemplateColumns: "repeat(3, 1fr)"' $autoFit | Out-Null
PatchReplace "src\app\eco\mural-acoes\MuralAcoesClient.tsx" 'gridTemplateColumns: "repeat(3, 1fr)"' $autoFit | Out-Null

# 5) Report
$reportDir = Join-Path $Root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ($me + "-" + $stamp + ".md")
$report = @()
$report += "# " + $me
$report += ""
$report += "- Time: " + $stamp
$report += "- Backup: " + $backupDir
$report += "- Patched:"
$report += "  - src/app/eco/mural/_components/MuralReadableStyles.tsx (container mais largo + tipografia)"
$report += "  - src/app/eco/mural/page.tsx (eco-mural-inner wrapper)"
$report += "  - src/app/eco/mural-acoes/page.tsx (eco-mural-inner wrapper, se existir)"
$report += "  - MuralClient/MuralAcoesClient (grid auto-fit, se encontrou)"
$report += ""
$report += "## Verify"
$report += "1) Ctrl+C -> npm run dev"
$report += "2) abrir /eco/mural (deve ocupar mais largura; topo sem vazio gigante)"
$report += "3) abrir /eco/mural-acoes (se existir; também legível e largo)"
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  (opcional) abrir /eco/mural-acoes"