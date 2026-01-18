param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-93-mural-confirmados-view-v0_1 == " + $ts)
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
if (-not (Get-Command WriteAllLinesUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteAllLinesUtf8NoBom([string]$p, [string[]]$lines) {
    EnsureDir (Split-Path -Parent $p)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($p, $lines, $enc)
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

function FindFirstFile([string]$root, [string]$name) {
  $hits = Get-ChildItem -LiteralPath (Join-Path $root "src") -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $name }
  if ($hits -and $hits.Count -gt 0) { return $hits[0].FullName }
  return $null
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-93-mural-confirmados-view-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$muralClient = Join-Path $Root "src/app/eco/mural/MuralClient.tsx"
if (-not (Test-Path -LiteralPath $muralClient)) { $muralClient = FindFirstFile $Root "MuralClient.tsx" }

$muralPage = Join-Path $Root "src/app/eco/mural/page.tsx"
if (-not (Test-Path -LiteralPath $muralPage)) { $muralPage = FindFirstFile $Root "page.tsx" }

$confirmadosPage = Join-Path $Root "src/app/eco/mural/confirmados/page.tsx"

if (-not $muralClient) { throw "[STOP] Nao achei MuralClient.tsx" }
if (-not $muralPage)   { throw "[STOP] Nao achei /eco/mural/page.tsx" }

Write-Host ("[DIAG] MuralClient: " + $muralClient)
Write-Host ("[DIAG] Mural page:  " + $muralPage)
Write-Host ("[DIAG] Will write:  " + $confirmadosPage)

BackupFile $Root $muralClient $backupDir
BackupFile $Root $muralPage   $backupDir
BackupFile $Root $confirmadosPage $backupDir

# 1) Write /eco/mural/confirmados page
$L = @(
'export const dynamic = "force-dynamic";',
'',
'import MuralClient from "../MuralClient";',
'',
'export default function Page() {',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>✅ Pontos confirmados</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Pontos que outras pessoas ja confirmaram (eu vi tambem). Sem algoritmo: so evidencia coletiva.',
'      </p>',
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", margin: "0 0 12px 0" }}>',
'        <a href="/eco/mural" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>',
'          Voltar ao mural',
'        </a>',
'        <a href="/eco/mural/chamados" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>',
'          Ver chamados',
'        </a>',
'      </div>',
'      <MuralClient base="confirmados" />',
'    </main>',
'  );',
'}'
)
WriteAllLinesUtf8NoBom $confirmadosPage $L
Write-Host "[PATCH] wrote /eco/mural/confirmados/page.tsx"

# 2) Patch /eco/mural/page.tsx: add link to confirmados (near chamados)
$rawP = Get-Content -LiteralPath $muralPage -Raw -ErrorAction Stop
if ($rawP -notmatch '/eco/mural/confirmados') {
  $linesP = $rawP -split "`n"
  $idx = -1
  for ($i=0; $i -lt $linesP.Count; $i++) {
    if ($linesP[$i] -match '/eco/mural/chamados') { $idx = $i; break }
  }
  if ($idx -ge 0) {
    $indent = ([regex]::Match($linesP[$idx], '^\s*')).Value
    $ins = @(
      $indent + '<a href="/eco/mural/confirmados" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>',
      $indent + '  ✅ Confirmados',
      $indent + '</a>'
    )
    $newP = New-Object System.Collections.Generic.List[string]
    for ($i=0; $i -lt $linesP.Count; $i++) {
      $newP.Add($linesP[$i])
      if ($i -eq $idx) { foreach ($x in $ins) { $newP.Add($x) } }
    }
    $rawP = ($newP -join "`n")
    WriteUtf8NoBom $muralPage $rawP
    Write-Host "[PATCH] mural/page.tsx: added link /eco/mural/confirmados"
  } else {
    Write-Host "[SKIP] Nao achei link de chamados no mural/page.tsx para inserir confirmados (ok)"
  }
} else {
  Write-Host "[SKIP] mural/page.tsx: link confirmados ja existe"
}

# 3) Patch MuralClient: when base == "confirmados", filter items by counts.confirm > 0 before setItems
$rawC = Get-Content -LiteralPath $muralClient -Raw -ErrorAction Stop
if ($rawC -notmatch 'base\s*===\s*["' + "'" + ']confirmados["' + "'" + ']') {
  $linesC = $rawC -split "`n"
  $setIdx = -1
  $argExpr = $null

  for ($i=0; $i -lt $linesC.Count; $i++) {
    if ($linesC[$i] -match 'setItems\s*\(') { $setIdx = $i; break }
  }

  if ($setIdx -ge 0) {
    $line = $linesC[$setIdx]
    $m = [regex]::Match($line, 'setItems\s*\(\s*([^)]+?)\s*\)\s*;')
    if ($m.Success) { $argExpr = $m.Groups[1].Value.Trim() }

    if (-not $argExpr) { $argExpr = "items" }

    $indent = ([regex]::Match($line, '^\s*')).Value
    $ins = @(
      $indent + 'const __items = ' + $argExpr + ';',
      $indent + 'const __arr = Array.isArray(__items) ? __items : [];',
      $indent + 'const __final = (base === "confirmados") ? __arr.filter((p: any) => Number((p as any)?.counts?.confirm || 0) > 0) : __arr;',
      $indent + 'setItems(__final);'
    )

    $newC = New-Object System.Collections.Generic.List[string]
    for ($i=0; $i -lt $linesC.Count; $i++) {
      if ($i -eq $setIdx) {
        foreach ($x in $ins) { $newC.Add($x) }
      } else {
        $newC.Add($linesC[$i])
      }
    }
    $rawC = ($newC -join "`n")
    WriteUtf8NoBom $muralClient $rawC
    Write-Host "[PATCH] MuralClient: added base==confirmados filter before setItems"
  } else {
    Write-Host "[SKIP] Nao achei setItems(...) no MuralClient.tsx para injetar filtro"
  }
} else {
  Write-Host "[SKIP] MuralClient: confirmados filter parece ja existir"
}

# report
$rep = Join-Path $reportDir ("eco-step-93-mural-confirmados-view-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-93-mural-confirmados-view-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Added route: src/app/eco/mural/confirmados/page.tsx",
"- Patched: src/app/eco/mural/page.tsx (link Confirmados)",
"- Patched: src/app/eco/mural/MuralClient.tsx (base==confirmados => filtra counts.confirm > 0 antes de setItems)",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) /eco/mural (tem botao ✅ Confirmados)",
"3) /eco/mural/confirmados (lista apenas pontos com counts.confirm > 0)",
"",
"## Notes",
"- Este tijolo nao depende de API nova: filtra no client usando counts.confirm vindo do payload.",
"- Se aparecer vazio, pode ser que seus pontos ainda nao tenham confirmacoes gravadas."
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> botao ✅ Confirmados"
Write-Host "[VERIFY] /eco/mural/confirmados"