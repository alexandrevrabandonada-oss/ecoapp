param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-96-points-alias-route-v0_1 == " + $ts)
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
      EnsureDir (Split-Path -Parent $dest)
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

function FindFileBySuffix([string]$root, [string]$suffix) {
  $src = Join-Path $root "src"
  if (-not (Test-Path -LiteralPath $src)) { return $null }
  $hits = Get-ChildItem -LiteralPath $src -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    ($_.FullName -replace '\\','/') -like ('*/' + $suffix)
  }
  if ($hits -and $hits.Count -ge 1) { return $hits[0].FullName }
  return $null
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-96-points-alias-route-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$list2 = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
if (-not (Test-Path -LiteralPath $list2)) { $list2 = FindFileBySuffix $Root "app/api/eco/points/list2/route.ts" }
if (-not $list2) { throw "[STOP] Nao achei: src/app/api/eco/points/list2/route.ts" }

$alias = Join-Path $Root "src/app/api/eco/points/route.ts"
if (-not (Test-Path -LiteralPath (Split-Path -Parent $alias))) {
  EnsureDir (Split-Path -Parent $alias)
}

Write-Host ("[DIAG] list2:  " + $list2)
Write-Host ("[DIAG] alias:  " + $alias)
BackupFile $Root $alias $backupDir

# route.ts: GET proxy para list2 (sem duplicar codigo e sem multiline strings)
$L = New-Object System.Collections.Generic.List[string]
$L.Add('import { GET as GET_LIST2 } from "./list2/route";')
$L.Add('')
$L.Add('export const runtime = "nodejs";')
$L.Add('export const dynamic = "force-dynamic";')
$L.Add('')
$L.Add('export async function GET(req: Request) {')
$L.Add('  return GET_LIST2(req);')
$L.Add('}')
$codeOut = ($L -join "`n")

WriteUtf8NoBom $alias $codeOut
Write-Host "[PATCH] wrote src/app/api/eco/points/route.ts (alias -> list2)"

$rep = Join-Path $reportDir ("eco-step-96-points-alias-route-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-96-points-alias-route-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Added/Updated: src/app/api/eco/points/route.ts",
"- Behavior: /api/eco/points (GET) delega para /api/eco/points/list2",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) http://localhost:3000/api/eco/points?limit=10 (200)",
"3) http://localhost:3000/api/eco/points/list2?limit=10 (200)",
"4) /eco/mural e /eco/mural/confirmados (se existir) nao devem mais chamar /api/eco/points 404"
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] http://localhost:3000/api/eco/points?limit=10"
Write-Host "[VERIFY] http://localhost:3000/api/eco/points/list2?limit=10"