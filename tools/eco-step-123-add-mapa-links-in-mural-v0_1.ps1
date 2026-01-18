param([string]$Root = (Get-Location).Path)

$ErrorActionPreference = "Stop"
$me = "eco-step-123-add-mapa-links-in-mural-v0_1"
$stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

# --- bootstrap (prefer tools/_bootstrap.ps1; fallback se quebrar)
$boot = Join-Path $Root "tools\_bootstrap.ps1"
$bootOk = $false
if (Test-Path -LiteralPath $boot) {
  try { . $boot; $bootOk = $true } catch { $bootOk = $false }
}

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){return}; New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$path,[string]$content){
    $enc = New-Object System.Text.UTF8Encoding($false)
    EnsureDir (Split-Path -Parent $path)
    [System.IO.File]::WriteAllText($path, $content, $enc)
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$src,[string]$backupDir){
    if(!(Test-Path -LiteralPath $src)){ return }
    EnsureDir $backupDir
    $leaf = Split-Path -Leaf $src
    $safeLeaf = ($leaf -replace '[^\w\.\-]+','_')
    $dst = Join-Path $backupDir ($safeLeaf + ".bak")
    Copy-Item -Force -LiteralPath $src -Destination $dst
    Write-Host ("[BK] " + $dst)
  }
}
if (-not (Get-Command NewReport -ErrorAction SilentlyContinue)) {
  function NewReport([string]$root,[string]$me,[string]$stamp,[string[]]$lines){
    $rp = Join-Path $root "reports"
    EnsureDir $rp
    $p = Join-Path $rp ($me + "-" + $stamp + ".md")
    WriteUtf8NoBom $p ($lines -join "`n")
    return $p
  }
}

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

# ===== PATCH A: /eco/mural/page.tsx -> botão "Abrir Mapa"
$page = Join-Path $Root "src\app\eco\mural\page.tsx"
if (!(Test-Path -LiteralPath $page)) { throw ("[STOP] Não achei: " + $page) }

$raw = Get-Content -Raw -LiteralPath $page
if ($raw -and ($raw -notmatch 'href="/eco/mapa"')) {
  BackupFile $page $backupDir
  $lines = $raw -split "`r?`n"
  $out = New-Object System.Collections.Generic.List[string]
  $inserted = $false

  for ($i=0; $i -lt $lines.Count; $i++) {
    $out.Add($lines[$i])

    if (-not $inserted -and ($lines[$i] -match 'Mural do Cuidado')) {
      # tenta inserir logo após o primeiro </p> depois do título
      $jMax = [Math]::Min($lines.Count-1, $i+15)
      $did = $false
      for ($j=$i; $j -le $jMax; $j++) {
        if ($lines[$j] -match '</p>') {
          # insere logo depois dessa linha (quando estivermos passando por ela)
          # marcamos para inserir no loop principal
          $did = $true
          break
        }
      }

      if (-not $did) {
        # se não achou </p> perto, insere já
        $out.Add('      <div style={{ margin: "8px 0 10px 0" }}>')
        $out.Add('        <a href="/eco/mapa" style={{ fontWeight: 900, textDecoration: "none", border: "1px solid #111", borderRadius: 999, padding: "8px 12px", background: "#fff", display: "inline-flex", gap: 8, alignItems: "center" }}>🗺️ Abrir Mapa</a>')
        $out.Add('      </div>')
        $inserted = $true
      }
    }

    # se detectou </p> perto do título, insere quando passar pelo </p>
    if (-not $inserted -and ($lines[$i] -match '</p>') -and ($raw -match 'Mural do Cuidado')) {
      # garante que estamos na primeira descrição do bloco (heurística: antes do primeiro "Chamados" ou antes de <MuralClient)
      if ($i -lt 120 -and ($raw -notmatch 'href="/eco/mapa"')) {
        $out.Add('      <div style={{ margin: "8px 0 10px 0" }}>')
        $out.Add('        <a href="/eco/mapa" style={{ fontWeight: 900, textDecoration: "none", border: "1px solid #111", borderRadius: 999, padding: "8px 12px", background: "#fff", display: "inline-flex", gap: 8, alignItems: "center" }}>🗺️ Abrir Mapa</a>')
        $out.Add('      </div>')
        $inserted = $true
      }
    }
  }

  $new = ($out -join "`n")
  WriteUtf8NoBom $page $new
  Write-Host ("[PATCH] added /eco/mapa button -> " + $page)
} else {
  Write-Host ("[SKIP] /eco/mapa button já existe em " + $page)
}

# ===== PATCH B: inserir link "🗺️ Mapa" nos cards (MuralClient e MuralAcoesClient)
$targets = @(
  (Join-Path $Root "src\app\eco\mural\MuralClient.tsx"),
  (Join-Path $Root "src\app\eco\mural-acoes\MuralAcoesClient.tsx")
)

$patchedCards = @()

foreach ($t in $targets) {
  if (!(Test-Path -LiteralPath $t)) { continue }
  $r = Get-Content -Raw -LiteralPath $t
  if (-not $r) { continue }
  if ($r -match 'openstreetmap\.org') { Write-Host ("[SKIP] já tem link de mapa -> " + $t); continue }

  if ($r -notmatch 'MuralPointActionsClient') {
    Write-Host ("[WARN] não achei MuralPointActionsClient para injetar mapa em: " + $t)
    continue
  }

  BackupFile $t $backupDir

  $ls = $r -split "`r?`n"
  $o = New-Object System.Collections.Generic.List[string]
  $didInsert = $false

  foreach ($line in $ls) {
    $o.Add($line)

    if (-not $didInsert -and ($line -match 'MuralPointActionsClient')) {
      $var = "p"
      if ($line -match 'point=\{([A-Za-z_]\w*)\}') { $var = $Matches[1] }
      elseif ($line -match 'pointId=\{([A-Za-z_]\w*)\.id\}') { $var = $Matches[1] }
      elseif ($line -match 'id=\{([A-Za-z_]\w*)\.id\}') { $var = $Matches[1] }

      $o.Add(('      <a href={"https://www.openstreetmap.org/?mlat=" + String(' + $var + '.lat) + "&mlon=" + String(' + $var + '.lng) + "#map=19/" + String(' + $var + '.lat) + "/" + String(' + $var + '.lng)} target="_blank" rel="noreferrer" style={{ fontSize: 12, fontWeight: 900, textDecoration: "none", border: "1px solid #111", borderRadius: 999, padding: "6px 10px", background: "#fff", display: "inline-flex", gap: 6, alignItems: "center", marginTop: 6 }}>🗺️ Mapa</a>'))
      $didInsert = $true
    }
  }

  $newT = ($o -join "`n")
  WriteUtf8NoBom $t $newT
  $patchedCards += $t
  Write-Host ("[PATCH] injected card map link -> " + $t)
}

# ===== REPORT
$rep = @()
$rep += "# $me"
$rep += ""
$rep += "- Time: $stamp"
$rep += "- Backup: $backupDir"
$rep += ""
$rep += "## Patched"
$rep += "- src/app/eco/mural/page.tsx (botão 🗺️ Abrir Mapa)"
if ($patchedCards.Count -gt 0) {
  $rep += "- Cards (link 🗺️ Mapa no OpenStreetMap):"
  foreach ($x in $patchedCards) { $rep += "  - $x" }
} else {
  $rep += "- Cards: (nenhum arquivo patchado — verificar warnings no log)"
}
$rep += ""
$rep += "## Verify"
$rep += "1) Ctrl+C -> npm run dev"
$rep += "2) abrir /eco/mural e clicar 🗺️ Abrir Mapa"
$rep += "3) nos cards, clicar 🗺️ Mapa (abre OpenStreetMap em nova aba)"
$rep += "4) abrir /eco/mapa (lista + links Abrir)"

$reportPath = NewReport $Root $me $stamp $rep
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  clicar 🗺️ Abrir Mapa"
Write-Host "  clicar 🗺️ Mapa num card"
Write-Host "  abrir /eco/mapa"