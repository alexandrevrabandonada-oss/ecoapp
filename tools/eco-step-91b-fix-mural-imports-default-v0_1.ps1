param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-91b-fix-mural-imports-default-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$p, [string]$content) {
    EnsureDir (Split-Path -Parent $p)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($p, $content, $enc)
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$root, [string]$p, [string]$backupDir) {
    if (Test-Path -LiteralPath $p) {
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-91b-fix-mural-imports-default-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$muralClient = Join-Path $Root "src/app/eco/mural/MuralClient.tsx"
$muralPage   = Join-Path $Root "src/app/eco/mural/page.tsx"
$chamadosPage= Join-Path $Root "src/app/eco/mural/chamados/page.tsx"

if (-not (Test-Path -LiteralPath $muralClient)) { throw "[STOP] Nao achei: src/app/eco/mural/MuralClient.tsx" }
if (-not (Test-Path -LiteralPath $muralPage))   { throw "[STOP] Nao achei: src/app/eco/mural/page.tsx" }
if (-not (Test-Path -LiteralPath $chamadosPage)){ throw "[STOP] Nao achei: src/app/eco/mural/chamados/page.tsx" }

Write-Host ("[DIAG] MuralClient: " + $muralClient)
Write-Host ("[DIAG] Mural page: " + $muralPage)
Write-Host ("[DIAG] Chamados page: " + $chamadosPage)

BackupFile $Root $muralClient $backupDir
BackupFile $Root $muralPage $backupDir
BackupFile $Root $chamadosPage $backupDir

# --- 1) Fix MuralClient import of PointActionsInline (use relative)
$raw = Get-Content -LiteralPath $muralClient -Raw -ErrorAction Stop

$re = [regex]'import\s+PointActionsInline\s+from\s+["''][^"'']+["''];?'
if ($re.IsMatch($raw)) {
  $raw2 = $re.Replace($raw, 'import PointActionsInline from "../_components/PointActionsInline";', 1)
} else {
  # insert after imports
  $pos = $raw.IndexOf("`n`n")
  if ($pos -gt 0) {
    $raw2 = $raw.Insert($pos+2, 'import PointActionsInline from "../_components/PointActionsInline";' + "`n")
  } else {
    $raw2 = 'import PointActionsInline from "../_components/PointActionsInline";' + "`n" + $raw
  }
}
WriteUtf8NoBom $muralClient $raw2
Write-Host "[PATCH] MuralClient: PointActionsInline import -> relative"

# ensure MuralClient exports default (guardrail)
$raw3 = Get-Content -LiteralPath $muralClient -Raw -ErrorAction Stop
if ($raw3 -notmatch 'export\s+default\s+function\s+MuralClient') {
  if ($raw3 -match 'function\s+MuralClient\s*\(') {
    $raw3b = [regex]::Replace($raw3, 'function\s+MuralClient\s*\(', 'export default function MuralClient(', 1)
    WriteUtf8NoBom $muralClient $raw3b
    Write-Host "[PATCH] MuralClient: ensured export default"
  } else {
    Write-Host "[WARN] Nao achei function MuralClient(…) para forcar export default."
  }
}

# --- 2) Fix mural/page.tsx import style (default import)
$mp = Get-Content -LiteralPath $muralPage -Raw -ErrorAction Stop
if ($mp -match 'import\s+\{\s*MuralClient\s*\}\s+from') {
  $mp2 = [regex]::Replace($mp, 'import\s+\{\s*MuralClient\s*\}\s+from\s+["''][^"'']+["''];?', 'import MuralClient from "./MuralClient";', 1)
  WriteUtf8NoBom $muralPage $mp2
  Write-Host "[PATCH] mural/page.tsx: named -> default import"
} elseif ($mp -match 'import\s+MuralClient\s+from') {
  # ok, but ensure path
  $mp2 = [regex]::Replace($mp, 'import\s+MuralClient\s+from\s+["''][^"'']+["''];?', 'import MuralClient from "./MuralClient";', 1)
  WriteUtf8NoBom $muralPage $mp2
  Write-Host "[PATCH] mural/page.tsx: normalized import path"
} else {
  # insert import at top
  $ins = 'import MuralClient from "./MuralClient";' + "`n"
  $mp2 = $ins + $mp
  WriteUtf8NoBom $muralPage $mp2
  Write-Host "[PATCH] mural/page.tsx: inserted default import"
}

# --- 3) Fix chamados/page.tsx import style (default import, correct path)
$cp = Get-Content -LiteralPath $chamadosPage -Raw -ErrorAction Stop
if ($cp -match 'import\s+\{\s*MuralClient\s*\}\s+from') {
  $cp2 = [regex]::Replace($cp, 'import\s+\{\s*MuralClient\s*\}\s+from\s+["''][^"'']+["''];?', 'import MuralClient from "../MuralClient";', 1)
  WriteUtf8NoBom $chamadosPage $cp2
  Write-Host "[PATCH] chamados/page.tsx: named -> default import"
} elseif ($cp -match 'import\s+MuralClient\s+from') {
  $cp2 = [regex]::Replace($cp, 'import\s+MuralClient\s+from\s+["''][^"'']+["''];?', 'import MuralClient from "../MuralClient";', 1)
  WriteUtf8NoBom $chamadosPage $cp2
  Write-Host "[PATCH] chamados/page.tsx: normalized import path"
} else {
  $ins = 'import MuralClient from "../MuralClient";' + "`n"
  $cp2 = $ins + $cp
  WriteUtf8NoBom $chamadosPage $cp2
  Write-Host "[PATCH] chamados/page.tsx: inserted default import"
}

# --- report
$rep = Join-Path $reportDir ("eco-step-91b-fix-mural-imports-default-v0_1-" + $ts + ".md")
$lines = @(
"# eco-step-91b-fix-mural-imports-default-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- MuralClient: PointActionsInline import agora e relativo (../_components/PointActionsInline).",
"- MuralClient: garante export default function MuralClient.",
"- mural/page.tsx: garante import default MuralClient from ./MuralClient.",
"- chamados/page.tsx: garante import default MuralClient from ../MuralClient.",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) abrir /eco/mural (deve 200)",
"3) abrir /eco/mural/chamados (deve 200)"
)
WriteUtf8NoBom $rep ($lines -join "`n")
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] GET /eco/mural"
Write-Host "[VERIFY] GET /eco/mural/chamados"