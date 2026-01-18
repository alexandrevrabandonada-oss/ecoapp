param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"

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
      Write-Host ("[BK] " + $rel + " -> " + (Split-Path -Leaf $dest))
    }
  }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-72c-fix-finalizar-page-params-await-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ("== eco-step-72c-fix-finalizar-page-params-await-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

$target = Join-Path $Root "src/app/eco/mutiroes/[id]/finalizar/page.tsx"
if (-not (Test-Path -LiteralPath $target)) { throw ("[STOP] Não achei: " + $target) }

BackupFile $Root $target $backupDir

$raw = Get-Content -LiteralPath $target -Raw
if (-not $raw) { throw "[STOP] arquivo vazio/ilegível." }

$nl = "`n"
if ($raw.Contains("`r`n")) { $nl = "`r`n" }

# 1) garantir async
if ($raw -match 'export\s+default\s+function\s+Page') {
  $raw = [regex]::Replace($raw, 'export\s+default\s+function\s+Page', 'export default async function Page', 1)
} elseif ($raw -match 'export\s+default\s+async\s+function\s+Page') {
  # ok
} else {
  # tenta o caso "function Page" sem export default (raro)
  $raw = [regex]::Replace($raw, 'function\s+Page', 'async function Page', 1)
}

# 2) inserir "await params" de forma segura (mesmo se params já for objeto)
if (-not ($raw -match 'await\s*\(\s*params\s+as\s+any\s*\)') -and -not ($raw -match 'await\s+params')) {
  # insere logo após a abertura do bloco da função Page
  $raw2 = [regex]::Replace(
    $raw,
    '\)\s*\{\s*' + [regex]::Escape($nl),
    ") {" + $nl + "  const p: any = await (params as any);" + $nl + "  const id = String(p?.id || \"\");" + $nl,
    1
  )
  if ($raw2 -eq $raw) {
    # fallback: antes do primeiro "return ("
    $raw2 = [regex]::Replace(
      $raw,
      [regex]::Escape($nl) + '(\s*)return\s*\(',
      $nl + '$1const p: any = await (params as any);' + $nl + '$1const id = String(p?.id || "");' + $nl + '$1return(',
      1
    )
  }
  $raw = $raw2
}

# 3) trocar usos de params.id por id
$raw = $raw -replace 'params\.id', 'id'

WriteUtf8NoBom $target $raw
Write-Host "[PATCH] page.tsx agora usa await params e id seguro."

$rep = Join-Path $reportDir ("eco-step-72c-fix-finalizar-page-params-await-v0_1-" + $ts + ".md")
$repLines = @(
"# eco-step-72c-fix-finalizar-page-params-await-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"- File: src/app/eco/mutiroes/[id]/finalizar/page.tsx",
"",
"## O que mudou",
"- Page virou async",
"- Agora faz: const p:any = await (params as any); const id = String(p?.id||\"\")",
"- Substitui params.id por id",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) Abrir /eco/mutiroes/<id>/finalizar",
"3) Não pode mais ter overlay apontando params.id"
)
WriteUtf8NoBom $rep ($repLines -join $nl)
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mutiroes/<id>/finalizar"