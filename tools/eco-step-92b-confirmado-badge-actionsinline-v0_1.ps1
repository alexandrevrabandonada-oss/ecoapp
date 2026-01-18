param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-92b-confirmado-badge-actionsinline-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

function EnsureDir([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteAllLinesUtf8NoBom([string]$p, [string[]]$lines) {
  EnsureDir (Split-Path -Parent $p)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllLines($p, $lines, $enc)
}
function WriteUtf8NoBom([string]$p, [string]$content) {
  EnsureDir (Split-Path -Parent $p)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($p, $content, $enc)
}
function BackupFile([string]$root, [string]$p, [string]$backupDir) {
  if (Test-Path -LiteralPath $p) {
    $rel = $p.Substring($root.Length).TrimStart('\','/')
    $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
    Copy-Item -Force -LiteralPath $p -Destination $dest
    Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
  }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-92b-confirmado-badge-actionsinline-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$actionsFile = Join-Path $Root "src/app/eco/_components/PointActionsInline.tsx"
$badgeFile   = Join-Path $Root "src/app/eco/_components/ConfirmadoBadge.tsx"

if (-not (Test-Path -LiteralPath $actionsFile)) { throw "[STOP] Nao achei: src/app/eco/_components/PointActionsInline.tsx" }

Write-Host ("[DIAG] ActionsInline: " + $actionsFile)
Write-Host ("[DIAG] Will write: " + $badgeFile)

BackupFile $Root $actionsFile $backupDir
BackupFile $Root $badgeFile $backupDir

# 1) Write ConfirmadoBadge.tsx (sem gambi, TSX limpo)
$badgeLines = @(
'"use client";',
'',
'type AnyObj = any;',
'',
'function pickNumber(v: any): number {',
'  const n = Number(v);',
'  return Number.isFinite(n) ? n : 0;',
'}',
'',
'function getCountFrom(obj: AnyObj, keys: string[]): number {',
'  if (!obj) return 0;',
'',
'  for (const k of keys) {',
'    const v = (obj as any)?.[k];',
'    const n = pickNumber(v);',
'    if (n > 0) return n;',
'  }',
'',
'  const holders = [',
'    (obj as any)?.counts,',
'    (obj as any)?.stats,',
'    (obj as any)?.actions,',
'    (obj as any)?.meta?.counts,',
'    (obj as any)?.meta?.stats,',
'  ].filter(Boolean);',
'',
'  for (const h of holders) {',
'    for (const k of keys) {',
'      const n = pickNumber((h as any)?.[k]);',
'      if (n > 0) return n;',
'    }',
'  }',
'',
'  const arrs = [',
'    (obj as any)?.confirmations,',
'    (obj as any)?.confirms,',
'    (obj as any)?.confirmedBy,',
'    (obj as any)?.confirmBy,',
'  ].filter(Boolean);',
'',
'  for (const a of arrs) {',
'    if (Array.isArray(a) && a.length > 0) return a.length;',
'  }',
'',
'  return 0;',
'}',
'',
'export default function ConfirmadoBadge({ data }: { data: AnyObj }) {',
'  const n =',
'    getCountFrom(data, ["confirm", "confirmar", "confirmed", "confirmations", "confirmCount", "confirmarCount"]) ||',
'    getCountFrom((data as any)?.counts, ["confirm", "confirmar", "confirmed"]) ||',
'    0;',
'',
'  if (!n || n <= 0) return null;',
'',
'  return (',
'    <span',
'      title={"Confirmado por " + n}',
'      style={{',
'        display: "inline-flex",',
'        alignItems: "center",',
'        gap: 8,',
'        padding: "5px 10px",',
'        borderRadius: 999,',
'        border: "1px solid #111",',
'        background: "#fff",',
'        fontWeight: 900,',
'        fontSize: 12,',
'        lineHeight: "12px",',
'        whiteSpace: "nowrap",',
'      }}',
'    >',
'      ✅ CONFIRMADO',
'      <span',
'        style={{',
'          display: "inline-flex",',
'          alignItems: "center",',
'          justifyContent: "center",',
'          minWidth: 20,',
'          padding: "2px 8px",',
'          borderRadius: 999,',
'          background: "#111",',
'          color: "#fff",',
'          fontWeight: 900,',
'          fontSize: 12,',
'          lineHeight: "12px",',
'        }}',
'      >',
'        {n}',
'      </span>',
'    </span>',
'  );',
'}'
)
WriteAllLinesUtf8NoBom $badgeFile $badgeLines
Write-Host "[PATCH] wrote ConfirmadoBadge.tsx"

# 2) Patch PointActionsInline.tsx (import + render badge)
$raw = Get-Content -LiteralPath $actionsFile -Raw -ErrorAction Stop

# 2a) add import if missing
if ($raw -notmatch 'ConfirmadoBadge') {
  $lines = $raw -split "`n"
  $lastImport = -1
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*import\s+') { $lastImport = $i }
  }

  $imp = 'import ConfirmadoBadge from "./ConfirmadoBadge";'

  $new = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines.Count; $i++) {
    $new.Add($lines[$i])
    if ($i -eq $lastImport) { $new.Add($imp) }
  }
  $raw = ($new -join "`n")
  Write-Host "[PATCH] ActionsInline: added import ConfirmadoBadge"
}

# 2b) decide which prop var to pass (point/item/data or propsVar)
$varExpr = $null

# try destructured signature: PointActionsInline({ ... })
$m1 = [regex]::Match($raw, 'PointActionsInline\s*\(\s*\{([^}]*)\}')
if ($m1.Success) {
  $inside = $m1.Groups[1].Value
  $names = $inside -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -notmatch '^\.\.\.' }
  foreach ($cand in @('point','item','data','p','row')) {
    foreach ($n in $names) {
      if ($n -match ('^\b' + $cand + '\b')) { $varExpr = $cand; break }
    }
    if ($varExpr) { break }
  }
}

# try "const { ... } = props"
if (-not $varExpr) {
  $m2 = [regex]::Match($raw, 'const\s*\{\s*([^}]*)\}\s*=\s*([A-Za-z_]\w*)')
  if ($m2.Success) {
    $inside = $m2.Groups[1].Value
    $propsVar = $m2.Groups[2].Value
    $names = $inside -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -notmatch '^\.\.\.' }
    foreach ($cand in @('point','item','data','p','row')) {
      foreach ($n in $names) {
        if ($n -match ('^\b' + $cand + '\b')) { $varExpr = $cand; break }
      }
      if ($varExpr) { break }
    }
    if (-not $varExpr) {
      $varExpr = '(' + $propsVar + ' as any).point ?? (' + $propsVar + ' as any).item ?? (' + $propsVar + ' as any).data ?? (' + $propsVar + ' as any)'
    }
  }
}

# try props param: PointActionsInline(props
if (-not $varExpr) {
  $m3 = [regex]::Match($raw, 'PointActionsInline\s*\(\s*([A-Za-z_]\w*)')
  if ($m3.Success) {
    $pv = $m3.Groups[1].Value
    $varExpr = '(' + $pv + ' as any).point ?? (' + $pv + ' as any).item ?? (' + $pv + ' as any).data ?? (' + $pv + ' as any)'
  }
}

if (-not $varExpr) {
  throw "[STOP] Nao consegui inferir a variavel do ponto no PointActionsInline.tsx. Cola aqui esse arquivo que eu ajusto certinho."
}

# 2c) inject badge line after root opening tag inside return (...)
$lines2 = $raw -split "`n"
$returnIdx = -1
for ($i=0; $i -lt $lines2.Count; $i++) {
  if ($lines2[$i] -match 'return\s*\(') { $returnIdx = $i; break }
}
if ($returnIdx -lt 0) { throw "[STOP] Nao achei 'return (' no PointActionsInline.tsx" }

$rootOpenIdx = -1
for ($i=($returnIdx+1); $i -lt $lines2.Count; $i++) {
  if ($lines2[$i] -match '^\s*<') { $rootOpenIdx = $i; break }
}
if ($rootOpenIdx -lt 0) { throw "[STOP] Nao achei a tag raiz do JSX no PointActionsInline.tsx" }

# avoid double insert
$already = $false
for ($j=[Math]::Max(0,$rootOpenIdx); $j -le [Math]::Min($lines2.Count-1,$rootOpenIdx+12); $j++) {
  if ($lines2[$j] -match 'ConfirmadoBadge') { $already = $true; break }
}

if (-not $already) {
  $indent = ([regex]::Match($lines2[$rootOpenIdx], '^\s*')).Value + "  "
  $badgeLine = $indent + '<ConfirmadoBadge data={' + $varExpr + '} />'

  $new2 = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines2.Count; $i++) {
    $new2.Add($lines2[$i])
    if ($i -eq $rootOpenIdx) { $new2.Add($badgeLine) }
  }
  $raw = ($new2 -join "`n")
  Write-Host ("[PATCH] ActionsInline: injected badge with data={" + $varExpr + "}")
} else {
  Write-Host "[SKIP] Badge ja existe no ActionsInline."
}

WriteUtf8NoBom $actionsFile $raw

# report
$rep = Join-Path $reportDir ("eco-step-92b-confirmado-badge-actionsinline-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-92b-confirmado-badge-actionsinline-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Added: src/app/eco/_components/ConfirmadoBadge.tsx",
"- Patched: src/app/eco/_components/PointActionsInline.tsx (import + badge render)",
"",
"## Badge data expression",
"- " + $varExpr,
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) /eco/mural e /eco/mural/chamados",
"3) Em pontos com contagem/confirmacoes no payload, aparece ✅ CONFIRMADO + numero"
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural e /eco/mural/chamados"