param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

# repo root = pasta acima de /tools
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")

function EnsureDir([string]$p) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function WriteUtf8NoBom([string]$path, [string]$content) {
  $enc = [Text.UTF8Encoding]::new($false)
  [IO.File]::WriteAllText($path, $content, $enc)
}

function BackupFile([string]$path, [string]$backupDir) {
  EnsureDir $backupDir
  if (Test-Path $path) {
    Copy-Item -Force $path (Join-Path $backupDir (Split-Path $path -Leaf)) | Out-Null
  }
}

function NewReport([string]$name) {
  $reportsDir = Join-Path $repoRoot "reports"
  EnsureDir $reportsDir
  return Join-Path $reportsDir ($stamp + "-" + $name + ".md")
}

$reportPath = NewReport "cv-b8p3-portals-meta-corenodes"
$log = New-Object System.Collections.Generic.List[string]

$log.Add("# CV B8P3 — Portais: meta.coreNodes fallback")
$log.Add("")
$log.Add("- Data: **$stamp**")
$log.Add("- Repo: $repoRoot")
$log.Add("")

$target = Join-Path $repoRoot "src\components\v2\Cv2PortalsCurated.tsx"

$log.Add("## DIAG")
$log.Add("")
$log.Add("- target: `$target = $target")
$log.Add("- exists: " + (Test-Path $target))
$log.Add("")

if (-not (Test-Path $target)) {
  $log.Add("[ERR] Arquivo nao encontrado.")
  WriteUtf8NoBom $reportPath ($log -join "`n")
  throw "Arquivo nao encontrado: $target"
}

$raw = Get-Content -Raw -Encoding UTF8 $target
if ([string]::IsNullOrWhiteSpace($raw)) {
  $log.Add("[ERR] Conteudo vazio.")
  WriteUtf8NoBom $reportPath ($log -join "`n")
  throw "Conteudo vazio: $target"
}

$backupDir = Join-Path $repoRoot ("tools\_patch_backup\b8p3-portals-meta-corenodes-" + $stamp)
BackupFile $target $backupDir

$log.Add("## PATCH")
$log.Add("")
$log.Add("- backup: $backupDir")
$changed = $false

# 1) expand Props para aceitar meta?: unknown
$needleProps = "type Props = { slug: string; active?: string; current?: string; coreNodes?: CoreNodesV2 };"
$replProps   = "type Props = { slug: string; active?: string; current?: string; coreNodes?: CoreNodesV2; meta?: unknown };"

if ($raw.Contains($needleProps)) {
  $raw = $raw.Replace($needleProps, $replProps)
  $changed = $true
  $log.Add("- Props: +meta?: unknown")
} elseif ($raw.Contains("meta?: unknown") -or $raw.Contains("meta?:")) {
  $log.Add("- Props: ja tem meta (sem mudanca)")
} else {
  $log.Add("[WARN] Nao achei a linha exata do Props; pulando replace do Props.")
}

# 2) inserir helper isRecord antes do type Props (se nao existir)
if ($raw -notmatch "function isRecord\(") {
  $idx = $raw.IndexOf("type Props =")
  if ($idx -gt 0) {
    $insert = @"
function isRecord(v: unknown): v is Record<string, unknown> {
  return !!v && typeof v === "object" && !Array.isArray(v);
}

"@
    $raw = $raw.Insert($idx, $insert)
    $changed = $true
    $log.Add("- add helper: isRecord()")
  } else {
    $log.Add("[WARN] Nao consegui inserir isRecord (nao achei 'type Props =').")
  }
} else {
  $log.Add("- helper isRecord(): ja existe")
}

# 3) usar meta.coreNodes quando coreNodes nao for passado
$needleOrder = "const order = coreNodesToDoorOrder(props.coreNodes);"
$replOrder = @"
const coreNodes =
  props.coreNodes ??
  (isRecord(props.meta) ? (props.meta["coreNodes"] as CoreNodesV2 | undefined) : undefined);
const order = coreNodesToDoorOrder(coreNodes);
"@

if ($raw.Contains($needleOrder)) {
  $raw = $raw.Replace($needleOrder, $replOrder)
  $changed = $true
  $log.Add("- order: agora faz fallback para meta.coreNodes")
} elseif ($raw -match "coreNodesToDoorOrder\(") {
  $log.Add("- order: parece ja estar custom (sem replace exato)")
} else {
  $log.Add("[WARN] Nao achei coreNodesToDoorOrder; nada para patchar aqui.")
}

if ($changed) {
  WriteUtf8NoBom $target $raw
  $log.Add("- wrote: $target")
} else {
  $log.Add("- sem mudanca em arquivo")
}

$log.Add("")
$log.Add("## VERIFY (runner canonico)")
$log.Add("")

$runner = Join-Path $repoRoot "tools\cv-runner.ps1"
if (Test-Path $runner) {
  $p = Start-Process -FilePath "pwsh" -ArgumentList @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File",$runner
  ) -Wait -PassThru
  $log.Add("- runner exit: " + $p.ExitCode)
} else {
  $log.Add("[WARN] runner nao encontrado: $runner")
}

WriteUtf8NoBom $reportPath ($log -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if ($OpenReport) {
  Start-Process $reportPath | Out-Null
}