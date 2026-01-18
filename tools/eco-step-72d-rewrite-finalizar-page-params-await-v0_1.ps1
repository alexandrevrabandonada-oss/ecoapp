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
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-72d-rewrite-finalizar-page-params-await-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-72d-rewrite-finalizar-page-params-await-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$target = Join-Path $Root 'src/app/eco/mutiroes/[id]/finalizar/page.tsx'
if (-not (Test-Path -LiteralPath $target)) { throw ('[STOP] Não achei: ' + $target) }

BackupFile $Root $target $backupDir

$lines = @(
'import MutiraoFinishClient from "./MutiraoFinishClient";',
'',
'export default async function Page({ params }: any) {',
'  const p: any = await (params as any);',
'  const id = String(p?.id || "");',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Finalizar mutirão</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Fecha o mutirão e (se tiver ponto vinculado) marca como RESOLVIDO com prova.',
'      </p>',
'      <MutiraoFinishClient id={id} />',
'    </main>',
'  );',
'}',
''
)

WriteUtf8NoBom $target ($lines -join "`n")
Write-Host '[PATCH] Reescreveu page.tsx com params await + id seguro.'

$rep = Join-Path $reportDir ('eco-step-72d-rewrite-finalizar-page-params-await-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-72d-rewrite-finalizar-page-params-await-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- File: src/app/eco/mutiroes/[id]/finalizar/page.tsx',
'',
'## O que mudou',
'- Page virou async e faz await(params) pra suportar Next 16',
'- Passa id seguro pro MutiraoFinishClient',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abrir /eco/mutiroes/<id>/finalizar (sem overlay de erro em params.id)'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] /eco/mutiroes/<id>/finalizar'