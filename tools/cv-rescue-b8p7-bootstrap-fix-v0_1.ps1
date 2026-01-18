param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

function EnsureDir([string]$p) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
function WriteUtf8NoBom([string]$path, [string]$content) {
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($path, $content, $enc)
}
function BackupFile([string]$path, [string]$tag = "backup") {
  $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
  $repo = (Resolve-Path ".").Path
  $dir = Join-Path $repo "tools\_patch_backup"
  EnsureDir $dir
  $base = Split-Path -Leaf $path
  $dst = Join-Path $dir ($tag + "-" + $stamp + "-" + $base)
  Copy-Item -Force $path $dst
  return $dst
}

$repo = (Resolve-Path ".").Path
$tools = Join-Path $repo "tools"
$reports = Join-Path $repo "reports"
EnsureDir $reports

$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$reportPath = Join-Path $reports ($stamp + "-cv-rescue-b8p7.md")

$log = New-Object System.Collections.Generic.List[string]
$log.Add("# CV RESCUE B8P7 + Bootstrap Fix v0.1")
$log.Add("")
$log.Add("- Repo: " + $repo)
$log.Add("- Date: " + $stamp)
$log.Add("")

# -------------------------
# PATCH 0: fix tools/_bootstrap.ps1 parse error (Mandatory=True -> Mandatory=$true)
# -------------------------
$bootstrap = Join-Path $tools "_bootstrap.ps1"
$log.Add("## PATCH 0 - bootstrap")
if (Test-Path $bootstrap) {
  $rawB = Get-Content -Raw -LiteralPath $bootstrap
  $rawB2 = $rawB

  $rawB2 = $rawB2 -replace "Mandatory\s*=\s*True", "Mandatory=`$true"
  $rawB2 = $rawB2 -replace "Mandatory\s*=\s*False", "Mandatory=`$false"

  if ($rawB2 -ne $rawB) {
    BackupFile $bootstrap "bootstrap"
    WriteUtf8NoBom $bootstrap $rawB2
    $log.Add("- OK: bootstrap patched (Mandatory=`$true/`$false)")
  } else {
    $log.Add("- OK: bootstrap already fine (no change)")
  }
} else {
  $log.Add("- WARN: missing tools/_bootstrap.ps1")
}
$log.Add("")

# -------------------------
# PATCH 1: ensure meta loader src/lib/v2/loadCadernoMeta.ts
# -------------------------
$log.Add("## PATCH 1 - meta loader")
$metaLib = Join-Path $repo "src\lib\v2\loadCadernoMeta.ts"
if (!(Test-Path $metaLib)) {
  EnsureDir (Split-Path -Parent $metaLib)

  $metaCode = @"
import { readFile } from "fs/promises";
import path from "path";

export type CadernoMeta = Record<string, unknown>;

function isRecord(v: unknown): v is Record<string, unknown> {
  return !!v && typeof v === "object" && !Array.isArray(v);
}

export async function loadCadernoMeta(slug: string): Promise<CadernoMeta> {
  const safeSlug = (slug || "").trim();
  if (!safeSlug) return {};
  const base = path.join(process.cwd(), "content", "cadernos", safeSlug);
  const file = path.join(base, "meta.json");
  try {
    const raw = await readFile(file, "utf8");
    const json = JSON.parse(raw) as unknown;
    return isRecord(json) ? (json as CadernoMeta) : {};
  } catch {
    return {};
  }
}
"@

  WriteUtf8NoBom $metaLib $metaCode
  $log.Add("- wrote: " + $metaLib)
} else {
  $log.Add("- exists: " + $metaLib + " (kept)")
}
$log.Add("")

# -------------------------
# PATCH 2: Cv2PortalsCurated accepts meta?: unknown (idempotent)
# -------------------------
$log.Add("## PATCH 2 - portals curated meta support")
$portalsCurated = Join-Path $repo "src\components\v2\Cv2PortalsCurated.tsx"
if (Test-Path $portalsCurated) {
  $raw = Get-Content -Raw -LiteralPath $portalsCurated
  $raw2 = $raw
  $did = $false

  if ($raw2 -notmatch "meta\?\s*:\s*unknown") {
    # best-effort: add meta?: unknown to Props type if it contains coreNodes?: CoreNodesV2
    if ($raw2 -match "type\s+Props\s*=\s*\{[\s\S]*?coreNodes\?\s*:\s*CoreNodesV2[\s\S]*?\};") {
      $raw2 = $raw2 -replace "coreNodes\?\s*:\s*CoreNodesV2\s*;", "coreNodes?: CoreNodesV2; meta?: unknown;"
      $did = $true
    }
  }

  # fallback in ordering call if present
  if ($raw2 -match "coreNodesToDoorOrder\(props\.coreNodes\)") {
    $raw2 = $raw2.Replace(
      "coreNodesToDoorOrder(props.coreNodes)",
      "coreNodesToDoorOrder(props.coreNodes ?? ((props.meta as any)?.coreNodes as any))"
    )
    $did = $true
  }

  if ($did -and ($raw2 -ne $raw)) {
    BackupFile $portalsCurated "b8p7-portalscurated"
    WriteUtf8NoBom $portalsCurated $raw2
    $log.Add("- patched: " + $portalsCurated)
  } else {
    $log.Add("- OK: no change needed")
  }
} else {
  $log.Add("- WARN: missing " + $portalsCurated)
}
$log.Add("")

# -------------------------
# PATCH 3: wire meta + blocks in src/app/c/[slug]/v2/page.tsx (without touching HomeV2Hub props)
# -------------------------
$log.Add("## PATCH 3 - hub page wiring")
$hubPage = Join-Path $repo "src\app\c\[slug]\v2\page.tsx"
if (Test-Path $hubPage) {
  $raw = Get-Content -Raw -LiteralPath $hubPage

  function EnsureImport([string]$src, [string]$importLine) {
    if ($src -match [Regex]::Escape($importLine)) { return $src }
    $lines = $src -split "`n"
    $last = -1
    for ($i=0; $i -lt $lines.Count; $i++) {
      if ($lines[$i].Trim().StartsWith("import ")) { $last = $i }
    }
    if ($last -ge 0) {
      $out = @()
      $out += $lines[0..$last]
      $out += $importLine
      if ($last + 1 -le $lines.Count - 1) { $out += $lines[($last+1)..($lines.Count-1)] }
      return ($out -join "`n")
    }
    return $src
  }

  $raw2 = $raw
  $raw2 = EnsureImport $raw2 'import { loadCadernoMeta } from "@/lib/v2/loadCadernoMeta";'
  $raw2 = EnsureImport $raw2 'import Cv2CoreHighlights from "@/components/v2/Cv2CoreHighlights";'
  $raw2 = EnsureImport $raw2 'import Cv2PortalsCurated from "@/components/v2/Cv2PortalsCurated";'

  # add: const meta = await loadCadernoMeta(slug);
  if ($raw2 -notmatch "await\s+loadCadernoMeta\(slug\)") {
    $lines = $raw2 -split "`n"
    $idx = -1
    for ($i=0; $i -lt $lines.Count; $i++) {
      $t = $lines[$i]
      if ($t -match "slug" -and ($t -match "await\s+params" -or $t -match "params\.slug" -or $t -match "const\s+\{\s*slug\s*\}")) {
        $idx = $i
        break
      }
    }
    if ($idx -ge 0) {
      $out = @()
      $out += $lines[0..$idx]
      $out += '  const meta = await loadCadernoMeta(slug);'
      if ($idx + 1 -le $lines.Count - 1) { $out += $lines[($idx+1)..($lines.Count-1)] }
      $raw2 = ($out -join "`n")
    }
  }

  # insert blocks after HomeV2Hub usage (do NOT pass meta to HomeV2Hub)
  if ($raw2 -notmatch "Cv2PortalsCurated\s+slug=\{slug\}") {
    $lines = $raw2 -split "`n"
    $iHome = -1
    for ($i=0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match "<HomeV2Hub") { $iHome = $i; break }
    }
    if ($iHome -ge 0) {
      $end = $iHome
      for ($j=$iHome; $j -lt [Math]::Min($lines.Count, $iHome + 120); $j++) {
        if ($lines[$j] -match "/>" -or $lines[$j] -match "</HomeV2Hub>") { $end = $j; break }
      }

      $ins = @(
        '      <Cv2CoreHighlights slug={slug} meta={meta} />',
        '      <Cv2PortalsCurated slug={slug} meta={meta} />'
      )

      $out = @()
      $out += $lines[0..$end]
      $out += $ins
      if ($end + 1 -le $lines.Count - 1) { $out += $lines[($end+1)..($lines.Count-1)] }
      $raw2 = ($out -join "`n")
    }
  }

  if ($raw2 -ne $raw) {
    BackupFile $hubPage "b8p7-hubpage"
    WriteUtf8NoBom $hubPage $raw2
    $log.Add("- patched: " + $hubPage)
  } else {
    $log.Add("- OK: hub page already wired (no change)")
  }
} else {
  $log.Add("- WARN: missing " + $hubPage)
}
$log.Add("")

# -------------------------
# VERIFY
# -------------------------
$log.Add("## VERIFY")
WriteUtf8NoBom $reportPath ($log -join "`n")

$runner = Join-Path $tools "cv-runner.ps1"
if (!(Test-Path $runner)) { throw ("Missing runner: " + $runner) }

& $runner | Out-Null
$exit = $LASTEXITCODE
Add-Content -LiteralPath $reportPath -Value ("`n- runner exit: " + $exit) -Encoding UTF8

if ($exit -ne 0) {
  throw ("Runner failed with exit " + $exit + " (see report): " + $reportPath)
}

if ($OpenReport) { Invoke-Item $reportPath }
Write-Host ("OK: rescue done. Report: " + $reportPath)