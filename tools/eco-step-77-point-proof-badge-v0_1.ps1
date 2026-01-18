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

function DetectNewline([string]$s) {
  if ($s -match "`r`n") { return "`r`n" }
  return "`n"
}

function InsertAfter([string]$raw, [string]$needle, [string]$insert, [string]$nl) {
  $pos = $raw.IndexOf($needle)
  if ($pos -lt 0) { return $raw }
  $after = $raw.IndexOf($nl, $pos)
  if ($after -lt 0) { $after = $pos + $needle.Length }
  else { $after = $after + $nl.Length }
  return $raw.Insert($after, $insert)
}

function InsertAfterMainOpen([string]$raw, [string]$insert, [string]$nl) {
  $pos = $raw.IndexOf("<main")
  if ($pos -lt 0) { return $raw }
  $after = $raw.IndexOf(">", $pos)
  if ($after -lt 0) { return $raw }
  $after = $after + 1
  return $raw.Insert($after, $nl + $insert)
}

function ScoreFile([string]$path, [string]$content) {
  $s = 0
  $lp = $path.ToLowerInvariant()
  $lc = $content.ToLowerInvariant()

  if ($lp -match "\\eco\\") { $s += 5 }
  if ($lp -match "\\coleta\\p\\\[id\]\\") { $s += 40 }
  if ($lp -match "\\pontos\\\[id\]\\") { $s += 45 }
  if ($lp -match "\\points\\\[id\]\\") { $s += 45 }
  if ($lp -match "\\mapa\\") { $s += 10 }

  if ($lc.Contains("/api/eco/points")) { $s += 60 }
  if ($lc.Contains("/api/eco/point")) { $s += 50 }
  if ($lc.Contains("/api/eco/pontos")) { $s += 60 }
  if ($lc.Contains("ponto")) { $s += 15 }
  if ($lc.Contains("critical")) { $s += 10 }
  if ($lc.Contains("status")) { $s += 6 }
  if ($lc.Contains("resolv")) { $s += 10 }
  if ($lc.Contains("mutirao")) { $s += 8 }

  # prefer client-ish files
  if ($lc.Contains('"use client"') -or $lc.Contains("'use client'")) { $s += 10 }
  if ($lp -match "client\.tsx$") { $s += 8 }

  return $s
}

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-77-point-proof-badge-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-77-point-proof-badge-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

# pick best candidate file (tsx) under src/app
$srcApp = Join-Path $Root 'src/app'
if (-not (Test-Path -LiteralPath $srcApp)) { throw ('[STOP] Não achei src/app em ' + $Root) }

$cands = Get-ChildItem -Path $srcApp -Recurse -File -Filter '*.tsx' -ErrorAction SilentlyContinue
if (-not $cands -or $cands.Count -eq 0) { throw "[STOP] Nenhum .tsx encontrado em src/app" }

$best = $null
$bestScore = -1

foreach ($f in $cands) {
  $p = $f.FullName
  # evita share/certificados etc
  if ($p -match "\\eco\\share\\") { continue }
  $raw = Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue
  if (-not $raw) { continue }

  # só considera arquivos com algum sinal de ponto/points
  $lc = $raw.ToLowerInvariant()
  if (-not ($lc.Contains("ponto") -or $lc.Contains("points") -or $lc.Contains("/api/eco/points") -or $lc.Contains("/api/eco/pontos") -or ($p -match "\\coleta\\p\\\[id\]\\"))) {
    continue
  }

  $sc = ScoreFile $p $raw
  if ($sc -gt $bestScore) {
    $bestScore = $sc
    $best = [PSCustomObject]@{ path = $p; score = $sc }
  }
}

if (-not $best) {
  throw "[STOP] Não encontrei um arquivo candidato para tela do ponto crítico."
}

$target = $best.path
Write-Host ('[DIAG] Target file: ' + $target)
Write-Host ('[DIAG] Score: ' + $best.score)

BackupFile $Root $target $backupDir

$rawT = Get-Content -LiteralPath $target -Raw
if (-not $rawT) { throw "[STOP] raw vazio no target" }
$nl = DetectNewline $rawT

if ($rawT -match "function\s+ProofBlock" -or $rawT -match "<ProofBlock") {
  Write-Host "[SKIP] Já parece ter ProofBlock/injeção."
} else {
  # detect main var name: point vs item vs ponto
  $countPoint = ([regex]::Matches($rawT, "point\?\.|point\.")).Count
  $countItem  = ([regex]::Matches($rawT, "item\?\.|item\.")).Count
  $countPonto = ([regex]::Matches($rawT, "ponto\?\.|ponto\.")).Count

  $varName = $null
  if ($countPonto -gt 0 -and $countPonto -ge $countPoint -and $countPonto -ge $countItem) { $varName = "ponto" }
  elseif ($countPoint -gt 0 -and $countPoint -ge $countItem) { $varName = "point" }
  elseif ($countItem -gt 0) { $varName = "item" }

  if (-not $varName) {
    throw "[STOP] Não consegui detectar variável principal (point/item/ponto) no arquivo alvo."
  }

  Write-Host ('[DIAG] Using var: ' + $varName)

  $injectLines = @(
'function normStatus(v: any) {',
'  return String(v || "").trim().toUpperCase();',
'}',
'function isResolved(s: string) {',
'  const t = normStatus(s);',
'  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";',
'}',
'function pickMeta(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return m || null;',
'}',
'function pickProof(p: any) {',
'  const m: any = pickMeta(p);',
'  const status = normStatus(p?.status || p?.state || m?.status || m?.state || "");',
'  const url = String(',
'    p?.proofUrl || p?.afterUrl || p?.resolvedProofUrl || p?.resolvedAfterUrl || p?.resolutionUrl ||',
'    m?.proofUrl || m?.afterUrl || m?.resolvedProofUrl || m?.resolvedAfterUrl || m?.resolutionUrl || m?.mutiraoAfterUrl ||',
'    ""',
'  ).trim();',
'  const note = String(',
'    p?.proofNote || p?.resolvedNote || p?.resolutionNote || p?.noteResolved ||',
'    m?.proofNote || m?.resolvedNote || m?.resolutionNote || m?.noteResolved ||',
'    ""',
'  ).trim();',
'  const mutiraoId = String(',
'    p?.mutiraoId || p?.mutiraoRefId || m?.mutiraoId || m?.mutiraoRefId || m?.mutirao || (p?.mutirao && p.mutirao.id) || ""',
'  ).trim();',
'  return { status, url, note, mutiraoId };',
'}',
'function StatusStamp(props: { status: string }) {',
'  const s = normStatus(props.status);',
'  const ok = isResolved(s);',
'  const label = ok ? "RESOLVIDO" : (s || "ABERTO");',
'  return (',
'    <span',
'      style={{',
'        display: "inline-block",',
'        padding: "6px 10px",',
'        borderRadius: 999,',
'        border: "1px solid #111",',
'        fontWeight: 900,',
'        background: ok ? "#B7FFB7" : "#FFDD00",',
'        color: "#111",',
'        textTransform: "uppercase",',
'        letterSpacing: 0.4,',
'        fontSize: 12,',
'      }}',
'    >',
'      {label}',
'    </span>',
'  );',
'}',
'function ProofBlock(props: { p: any }) {',
'  const pr = pickProof(props.p);',
'  const show = isResolved(pr.status) || !!pr.url || !!pr.note;',
'  if (!show) return null;',
'  return (',
'    <section style={{ border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff", margin: "12px 0" }}>',
'      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>',
'        <div style={{ fontWeight: 900 }}>Status do ponto</div>',
'        <StatusStamp status={pr.status} />',
'      </div>',
'',
'      <div style={{ marginTop: 10, display: "grid", gap: 10 }}>',
'        {pr.url ? (',
'          <div style={{ display: "grid", gap: 6 }}>',
'            <div style={{ fontSize: 13, opacity: 0.8 }}>Última prova (DEPOIS)</div>',
'            {/* eslint-disable-next-line @next/next/no-img-element */}',
'            <img src={pr.url} alt="Prova" style={{ width: "100%", maxWidth: 520, borderRadius: 14, border: "1px solid #111" }} />',
'          </div>',
'        ) : null}',
'',
'        {pr.note ? (',
'          <div style={{ border: "1px dashed #111", borderRadius: 14, padding: 10, background: "#fffef1" }}>',
'            <div style={{ fontSize: 13, opacity: 0.8, marginBottom: 6 }}>Nota</div>',
'            <div style={{ whiteSpace: "pre-wrap" }}>{pr.note}</div>',
'          </div>',
'        ) : null}',
'',
'        {pr.mutiraoId ? (',
'          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>',
'            <a href={"/eco/mutiroes/" + encodeURIComponent(pr.mutiraoId)} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111" }}>',
'              Ver mutirão',
'            </a>',
'            <a href={"/eco/share/mutirao/" + encodeURIComponent(pr.mutiraoId)} target="_blank" rel="noreferrer" style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", background: "#FFDD00", fontWeight: 900 }}>',
'              Compartilhar (card)',
'            </a>',
'          </div>',
'        ) : null}',
'      </div>',
'    </section>',
'  );',
'}'
  )

  $inject = ($injectLines -join $nl) + $nl + $nl

  # insert helper funcs near top: after last import or after "use client";
  if ($rawT -match "use client") {
    # after last import line
    $lastImport = [regex]::Matches($rawT, "(?m)^\s*import .+;\s*$")
    if ($lastImport.Count -gt 0) {
      $m = $lastImport[$lastImport.Count - 1]
      $pos = $m.Index + $m.Length
      $rawT = $rawT.Insert($pos, $nl + $inject)
    } else {
      $rawT = InsertAfter $rawT "use client" ($nl + $inject) $nl
    }
  } else {
    # server component file: still ok to inject funcs for JSX usage
    $lastImport2 = [regex]::Matches($rawT, "(?m)^\s*import .+;\s*$")
    if ($lastImport2.Count -gt 0) {
      $m2 = $lastImport2[$lastImport2.Count - 1]
      $pos2 = $m2.Index + $m2.Length
      $rawT = $rawT.Insert($pos2, $nl + $inject)
    } else {
      $rawT = $inject + $rawT
    }
  }

  # insert <ProofBlock p={VAR} /> after </h1> if exists, else after <main>
  $call = ('      <ProofBlock p={' + $varName + '} />') + $nl
  if ($rawT -match "</h1>") {
    $rawT = InsertAfter $rawT "</h1>" $call $nl
  } else {
    $rawT = InsertAfterMainOpen $rawT $call $nl
  }

  WriteUtf8NoBom $target $rawT
  Write-Host "[PATCH] Injected ProofBlock + StatusStamp + render call"
}

# REPORT
$rep = Join-Path $reportDir ('eco-step-77-point-proof-badge-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-77-point-proof-badge-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- Target: ' + ($target.Substring($Root.Length).TrimStart('\','/')),
'',
'## O que mudou',
'- Adiciona bloco "Status do ponto" com carimbo (RESOLVIDO/ABERTO)',
'- Mostra última prova (thumb do afterUrl/proofUrl) + nota (proofNote)',
'- Se existir mutiraoId, mostra links "Ver mutirão" e "Compartilhar (card)"',
'',
'## Keys (fallbacks)',
'- status: p.status | p.state | meta.status | meta.state',
'- url: p.proofUrl | p.afterUrl | p.resolvedProofUrl | meta.afterUrl | meta.proofUrl | ...',
'- note: p.proofNote | p.resolvedNote | meta.proofNote | ...',
'- mutiraoId: p.mutiraoId | meta.mutiraoId | p.mutirao.id | ...',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abrir a tela do ponto crítico (o mesmo que você usou pra resolver via mutirão)',
'3) Confirmar: carimbo RESOLVIDO + aparece a prova/nota quando existir'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] abrir a tela do ponto crítico resolvido e checar carimbo + prova"