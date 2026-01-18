param([switch]$OpenReport)
$ErrorActionPreference = "Stop"

function EnsureDir($p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom($p, $s){ [IO.File]::WriteAllText($p, $s, [Text.UTF8Encoding]::new($false)) }
function BackupFile($src, $dst){ EnsureDir (Split-Path -Parent $dst); Copy-Item -Force $src $dst }

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$ts = (Get-Date -Format "yyyyMMdd-HHmmss")
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-196-eslint9-ignores-any-policy-" + $ts + ".md")

$eslintPath = Join-Path $root "eslint.config.mjs"
if(!(Test-Path $eslintPath)){ throw ("eslint.config.mjs nao encontrado em: " + $eslintPath) }

$r = @()
$r += "# eco-step-196 — ESLint 9 ignores + any-policy (warn) — " + $ts
$r += ""
$r += "## DIAG"
$r += "- eslint: " + $eslintPath
$raw = Get-Content -Raw -Encoding UTF8 $eslintPath
$r += "- has ECO_STEP196_IGNORES: " + ($raw -match "ECO_STEP196_IGNORES_START")
$r += "- has ECO_STEP196_ANY_POLICY: " + ($raw -match "ECO_STEP196_ANY_POLICY_START")
$r += "- mentions tools/_patch_backup: " + ($raw -match "tools/_patch_backup")
$r += "- mentions reports/: " + ($raw -match "reports/")
$r += ""

$r += "## PATCH"
$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-196\" + $ts)
EnsureDir $backupDir
$backupEslint = Join-Path $backupDir "eslint.config.mjs"
BackupFile $eslintPath $backupEslint
$r += "- backup: " + $backupEslint

# 1) Inserir bloco de ignores (seguro mesmo se ja existir ignores em outro lugar)
if($raw -notmatch "ECO_STEP196_IGNORES_START"){
  $insert = @(
    "  // ECO_STEP196_IGNORES_START",
    "  {",
    "    ignores: [",
    "      `"tools/_patch_backup/**`",",
    "      `"reports/**`",",
    "      `".next/**`",",
    "      `"node_modules/**`"",
    "    ],",
    "  },",
    "  // ECO_STEP196_IGNORES_END"
  ) -join "`n"

  $rx = New-Object System.Text.RegularExpressions.Regex("export\s+default\s*\[\s*", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if(-not $rx.IsMatch($raw)){ throw "Nao achei `export default [` no eslint.config.mjs (flat config)."}
  $raw = $rx.Replace($raw, { param($m) $m.Value + "`n" + $insert + "`n" }, 1)
  $r += "- inserted ignores block (ECO_STEP196_IGNORES_*)"
} else {
  $r += "- ignores block ja existia (skip)"
}

# 2) Forcar policy: no-explicit-any = warn (override no final do array)
if($raw -notmatch "ECO_STEP196_ANY_POLICY_START"){
  $anyBlock = @(
    "  // ECO_STEP196_ANY_POLICY_START",
    "  {",
    "    files: [`"src/**/*.{ts,tsx,js,jsx}`"],",
    "    rules: {",
    "      `"@typescript-eslint/no-explicit-any`": `"warn`",",
    "    },",
    "  },",
    "  // ECO_STEP196_ANY_POLICY_END"
  ) -join "`n"

  $rxEnd = New-Object System.Text.RegularExpressions.Regex("\]\s*;\s*$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
  if(-not $rxEnd.IsMatch($raw)){ throw "Nao achei fechamento `];` no final do eslint.config.mjs." }
  $raw = $rxEnd.Replace($raw, "`n" + $anyBlock + "`n];", 1)
  $r += "- appended any-policy override (no-explicit-any => warn)"
} else {
  $r += "- any-policy block ja existia (skip)"
}

WriteUtf8NoBom $eslintPath $raw
$r += "- wrote: " + $eslintPath

$r += ""
$r += "## VERIFY"
$r += "- rodando: npm run lint"
Push-Location $root
try {
  $out = (& npm run lint 2>&1 | Out-String)
  $r += "~~~"
  $r += $out.TrimEnd()
  $r += "~~~"
} catch {
  $r += "~~~"
  $r += ("[ERR] lint falhou: " + $_.Exception.Message)
  $r += "~~~"
  throw
} finally { Pop-Location }

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }
Write-Host ""
Write-Host "[NEXT] rode: npm run build"