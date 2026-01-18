param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

function New-Stamp { (Get-Date).ToString("yyyyMMdd-HHmmss") }

# ---- bootstrap (preferencial)
$bootstrap = "tools\_bootstrap.ps1"
if(Test-Path -LiteralPath $bootstrap){ . $bootstrap }
else {
  function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p | Out-Null } }
  function WriteUtf8NoBom([string]$p,[string]$c){ [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($false)) }
  function BackupFile([string]$file,[string]$destDir){
    EnsureDir $destDir
    $name = ($file -replace "[:\\\\/]+","_")
    $stamp = New-Stamp
    $dst = Join-Path $destDir ($stamp + "-" + $name)
    Copy-Item -LiteralPath $file -Destination $dst -Force
    return $dst
  }
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode a partir da raiz do repo (onde tem package.json)." }

$stamp = New-Stamp
$step  = "eco-step-159"
$backupDir = Join-Path "tools\_patch_backup" $step
EnsureDir $backupDir
EnsureDir "reports"
$reportPath = Join-Path "reports" ($step + "-fix-actor-cookieheader-" + $stamp + ".md")

$patchLog = @()

function Patch-Actor([string]$file, [ref]$log){
  if(!(Test-Path -LiteralPath $file)){ $log.Value += "[SKIP] " + $file + " (nao existe)"; return }
  $raw = Get-Content -Raw -LiteralPath $file
  $orig = $raw
  $changed = $false

  # 1) remove import cookies (se existir)
  $rxImport = "(?m)^\\s*import\\s*\\{\\s*cookies\\s*\\}\\s*from\\s*[\"']next/headers[\"'];\\s*\\r?\\n"
  $raw2 = [regex]::Replace($raw, $rxImport, "")
  if($raw2 -ne $raw){ $raw = $raw2; $changed = $true }

  # 2) troca readActorFromReq para cookie header (evita cookies() async no Next 16)
  $hasReadCookie = ($raw -match "function\\s+readCookie\\s*\\(")

  $repA = @(
    "function readCookie(req: Request, name: string): string | null {",
    "  const h = req.headers.get(\"cookie\") || \"\";",
    "  const parts = h.split(/;\\s*/);",
    "  for (const p of parts) {",
    "    const eq = p.indexOf(\"=\");",
    "    if (eq <= 0) continue;",
    "    const k = p.slice(0, eq).trim();",
    "    if (k !== name) continue;",
    "    const v = p.slice(eq + 1);",
    "    try { return decodeURIComponent(v); } catch { return v; }",
    "  }",
    "  return null;",
    "}",
    "",
    "function readActorFromReq(req: Request, body: any): string {",
    "  const c1 = readCookie(req, \"eco_actor\");",
    "  const c2 = readCookie(req, \"nika_email\");",
    "  const h = req.headers.get(\"x-actor\");",
    "  const b = body && typeof body.actor === \"string\" ? body.actor : null;",
    "  return (h && h.trim()) || (b && b.trim()) || (c1 && c1.trim()) || (c2 && c2.trim()) || \"anon\";",
    "}"
  ) -join "`n"

  $repB = @(
    "function readActorFromReq(req: Request, body: any): string {",
    "  const c1 = readCookie(req, \"eco_actor\");",
    "  const c2 = readCookie(req, \"nika_email\");",
    "  const h = req.headers.get(\"x-actor\");",
    "  const b = body && typeof body.actor === \"string\" ? body.actor : null;",
    "  return (h && h.trim()) || (b && b.trim()) || (c1 && c1.trim()) || (c2 && c2.trim()) || \"anon\";",
    "}"
  ) -join "`n"

  $rxFn = "(?s)function\\s+readActorFromReq\\s*\\(\\s*req\\s*:\\s*Request\\s*,\\s*body\\s*:\\s*any\\s*\\)\\s*:\\s*string\\s*\\{.*?\\r?\\n\\}"
  if($raw -match $rxFn){
    $replacement = $(if($hasReadCookie){ $repB } else { $repA })
    $raw2 = [regex]::Replace($raw, $rxFn, $replacement)
    if($raw2 -ne $raw){ $raw = $raw2; $changed = $true }
  } else {
    # fallback: se nao achou a assinatura exata, tenta detectar uso de cookies().get e avisa
    if($raw -match "cookies\\(\\)\\.get\\("){
      $log.Value += "[WARN] " + $file + " tem cookies().get(...) mas nao achei funcao readActorFromReq com assinatura esperada. Ajuste manual pode ser necessario."
    } else {
      $log.Value += "[SKIP] " + $file + " (readActorFromReq nao encontrado)"
    }
  }

  if($changed -and ($raw -ne $orig)){
    $bk = BackupFile $file $backupDir
    WriteUtf8NoBom $file $raw
    $log.Value += "[OK]   " + $file + " (actor via cookie header; removed next/headers cookies import if present)"
    $log.Value += "       backup: " + $bk
  } elseif($changed){
    $log.Value += "[SKIP] " + $file + " (no effective change)"
  }
}

$targets = @(
  "src\app\api\eco\points\confirm\route.ts",
  "src\app\api\eco\points\replicar\route.ts",
  "src\app\api\eco\points\support\route.ts"
)
foreach($f in $targets){ Patch-Actor $f ([ref]$patchLog) }

# ---- VERIFY
function RunStep([string]$title, [scriptblock]$sb, [ref]$out){
  $out.Value += "### " + $title
  $out.Value += "~~~"
  try {
    $r = (& $sb 2>&1 | Out-String).TrimEnd()
    if($r){ $out.Value += $r }
  } catch {
    $out.Value += ("[ERR] " + $_.Exception.Message)
  }
  $out.Value += "~~~"
  $out.Value += ""
}

$verify = @()
RunStep "npm run build" { npm run build } ([ref]$verify)

# ---- REPORT
$r = @()
$r += ("# " + $step + " — fix actor cookie (cookie header) — " + $stamp)
$r += ""
$r += "## Patch log"
$r += "~~~"
$r += ($patchLog -join "`n")
$r += "~~~"
$r += ""
$r += "## VERIFY"
$r += ($verify -join "`n")
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }
Write-Host ""
Write-Host "[NEXT] se o build passar, rode:"
Write-Host "  pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport"