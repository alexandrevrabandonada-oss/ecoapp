param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
$root = (Get-Location).Path
if (!(Test-Path -LiteralPath (Join-Path $root "package.json"))) { throw "Rode na raiz do repo (onde tem package.json)." }

function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path,[string]$content){ [IO.File]::WriteAllText($path,$content,[Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file,[string]$backupDir){
  EnsureDir $backupDir
  if(!(Test-Path -LiteralPath $file)){ return "" }
  $name = Split-Path -Leaf $file
  $dst = Join-Path $backupDir ($name + ".bak")
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$target = Join-Path $root "src\components\eco\ReceiptShareBar.tsx"
if(!(Test-Path -LiteralPath $target)){ throw ("Nao achei: " + $target) }

$raw = Get-Content -Raw -Encoding UTF8 -LiteralPath $target
if($raw -match "\beco28_shareCard\b"){
  $patch = "[SKIP] eco28_shareCard ja existe."
} else {
  $idx = $raw.IndexOf("export default function")
  if($idx -lt 0){ throw "Nao achei: export default function (ponto de insercao)"}

  $insert = @(
    "",
    "// ECO_STEP28_SHARE_CARD_FN_START",
    "async function eco28_shareCard(code: string, format: ""3x4"" | ""1x1"") {",
    "  try {",
    "    if (!code) return;",
    "    if (typeof window === ""undefined"") return;",
    "    const path = ""/api/share/receipt-card?code="" + encodeURIComponent(code) + ""&format="" + encodeURIComponent(format);",
    "    const url = window.location.origin + path;",
    "    const nav: any = (typeof navigator !== ""undefined"") ? (navigator as any) : null;",
    "    if (nav && typeof nav.share === ""function"") {",
    "      try { await nav.share({ title: ""Recibo ECO"", url }); return; } catch {}",
    "    }",
    "    window.open(path, ""_blank"");",
    "  } catch {",
    "    try { if (typeof window !== ""undefined"") window.open(""/api/share/receipt-card?code="" + encodeURIComponent(code) + ""&format="" + encodeURIComponent(format), ""_blank""); } catch {}",
    "  }",
    "}",
    "// ECO_STEP28_SHARE_CARD_FN_END",
    ""
  ) -join "`n"

  $backupDir = Join-Path $root ("tools\_patch_backup\eco-step-193\" + $stamp)
  $bak = BackupFile $target $backupDir
  $newRaw = $raw.Insert($idx, $insert)
  WriteUtf8NoBom $target $newRaw
  $patch = "[OK] inseriu eco28_shareCard antes do export default function. backup=" + $bak
}

EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-193-fix-receiptsharebar-sharecard-" + $stamp + ".md")
$r = @()
$r += ("# eco-step-193 — fix ReceiptShareBar eco28_shareCard — " + $stamp)
$r += ""
$r += "## DIAG"
$r += "- alvo: src\components\eco\ReceiptShareBar.tsx"
$r += ""
$r += "## PATCH"
$r += "~~~"
$r += $patch
$r += "~~~"
$r += ""
$r += "## VERIFY"
$r += "- npm run build"

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }