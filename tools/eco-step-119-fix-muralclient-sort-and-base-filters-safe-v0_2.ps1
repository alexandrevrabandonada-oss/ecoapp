param(
  [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

function TryDotSourceBootstrap($rootPath) {
  $b1 = Join-Path $rootPath "tools\_bootstrap.ps1"
  if (Test-Path $b1) { . $b1; return $true }
  return $false
}

# --- fallback mínimo (se _bootstrap não carregar)
function EnsureDirFallback([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBomFallback([string]$p, [string]$content) {
  EnsureDirFallback (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $content, [System.Text.UTF8Encoding]::new($false))
}
function BackupFileFallback([string]$file, [string]$backupDir) {
  EnsureDirFallback $backupDir
  if (Test-Path $file) {
    $safe = ($file -replace "[:\\\/]", "_")
    Copy-Item -Force $file (Join-Path $backupDir $safe)
  }
}

$null = TryDotSourceBootstrap $Root

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) { Set-Alias EnsureDir EnsureDirFallback -Scope Script }
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) { Set-Alias WriteUtf8NoBom WriteUtf8NoBomFallback -Scope Script }
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) { Set-Alias BackupFile BackupFileFallback -Scope Script }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$me = "eco-step-119-fix-muralclient-sort-and-base-filters-safe-v0_2"
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

function PatchFile([string]$filePath) {
  if (-not (Test-Path $filePath)) {
    return @{ ok=$false; file=$filePath; msg="missing" }
  }

  $raw = Get-Content -Raw -ErrorAction Stop $filePath
  if (-not $raw) { return @{ ok=$false; file=$filePath; msg="empty" } }

  $orig = $raw

  # 1) corrigir "arr    try { \n .sort" => "try { \n arr.sort"
  $raw = [Regex]::Replace(
    $raw,
    "arr\s+try\s*\{\s*[\r\n]+\s*\.sort",
    "try {`n      arr.sort",
    [System.Text.RegularExpressions.RegexOptions]::Multiline
  )

  # 2) corrigir "p?.counts?." => "a?.counts?."
  $raw = $raw.Replace("p?.counts?.", "a?.counts?.")

  # 3) inserir helpers dt/score (se não existir)
  $hasScore = $raw.Contains("function score(") -or $raw.Contains("const score")
  if (-not $hasScore) {
    $insert = @(
      "",
      'function dt(v: any): number {',
      '  const n = Date.parse(String(v || ""));',
      '  return Number.isFinite(n) ? n : 0;',
      '}',
      "",
      'function score(p: any): number {',
      '  const c = (p && p.counts) ? p.counts : {};',
      '  const conf = num(c.confirm ?? p?.confirmCount ?? p?.confirm ?? 0);',
      '  const sup  = num(c.support ?? p?.supportCount ?? p?.support ?? 0);',
      '  const rep  = num(c.replicar ?? p?.replicarCount ?? p?.replicar ?? 0);',
      '  return conf + sup + rep;',
      '}',
      ""
    ) -join "`n"

    $idxNum = $raw.IndexOf("function num(")
    if ($idxNum -ge 0) {
      $end = $raw.IndexOf("}", $idxNum)
      if ($end -gt $idxNum) {
        $end = $end + 1
        $raw = $raw.Substring(0, $end) + $insert + $raw.Substring($end)
      } else {
        $raw = $insert + $raw
      }
    } else {
      $raw = $insert + $raw
    }
  }

  # 4) base filters: confirmados => confirm>0 ; acoes => score>0
  if (-not $raw.Contains('view.includes("confirm")')) {
    $m = [Regex]::Match($raw, "(?m)^\s*const\s+arr\s*=\s*.+;$")
    if ($m.Success) {
      $line = $m.Value
      $line2 = $line.Replace("const arr", "let arr")
      $filters = @(
        '      const view = String(base || "pontos").toLowerCase();',
        '      if (view.includes("confirm")) {',
        '        arr = arr.filter((x: any) => num(x?.counts?.confirm ?? x?.confirmCount ?? 0) > 0);',
        '      }',
        '      if (view.includes("acoes")) {',
        '        arr = arr.filter((x: any) => score(x) > 0);',
        '      }'
      ) -join "`n"
      $raw = $raw.Replace($line, ($line2 + "`n" + $filters))
    }
  }

  # 5) normalizar sort por score + createdAt (best-effort)
  if ($raw.Contains("arr.sort(")) {
    $raw = [Regex]::Replace(
      $raw,
      "arr\.sort\(\(a:\s*any,\s*b:\s*any\)\s*=>\s*\{[\s\S]*?\}\)\s*;",
@"
arr.sort((a: any, b: any) => {
        const sa = score(a);
        const sb = score(b);
        if (sb !== sa) return sb - sa;
        const ta = dt(a?.createdAt);
        const tb = dt(b?.createdAt);
        return tb - ta;
      });
"@,
      [System.Text.RegularExpressions.RegexOptions]::Multiline
    )
  }

  if ($raw -ne $orig) {
    BackupFile $filePath $backupDir
    WriteUtf8NoBom $filePath $raw
    return @{ ok=$true; file=$filePath; msg="patched" }
  }

  return @{ ok=$true; file=$filePath; msg="no_change" }
}

$targets = @(
  (Join-Path $Root "src\app\eco\mural\MuralClient.tsx"),
  (Join-Path $Root "src\app\eco\mural-acoes\MuralAcoesClient.tsx")
)

$results = @()
foreach ($t in $targets) { $results += (PatchFile $t) }

# --- REPORT
$report = @()
$report += "# $me"
$report += ""
$report += "- Time: $stamp"
$report += "- Backup: $backupDir"
$report += ""
$report += "## Results"
foreach ($r in $results) { $report += ("- " + $r.file + " :: " + $r.msg) }
$report += ""
$report += "## What/Why"
$report += "- Corrige sort quebrado (arr try / p is not defined)."
$report += "- Sort por score(confirm+support+replicar) + desempate por createdAt."
$report += "- Filtros por base: confirmados (confirm>0) e acoes (score>0)."
$report += ""
$report += "## Verify"
$report += "1) Ctrl+C -> npm run dev"
$report += "2) abrir /eco/mural"
$report += "3) abrir /eco/mural/confirmados"
$report += "4) (opcional) abrir /eco/mural-acoes"
$report += "5) testar API actions:"
$report += "   `$pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id"
$report += "   `$b = @{ pointId = `$pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress"
$report += "   irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body `$b | ConvertTo-Json -Depth 60"

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  abrir /eco/mural/confirmados"
Write-Host "  (opcional) abrir /eco/mural-acoes"
Write-Host "  `$pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id"
Write-Host "  `$b = @{ pointId = `$pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress"
Write-Host "  irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body `$b | ConvertTo-Json -Depth 60"