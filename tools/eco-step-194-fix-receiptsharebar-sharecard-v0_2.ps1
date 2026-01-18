param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
function EnsureDir([string]$p) { if (!(Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p, [string]$content) { [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file, [string]$tag) {
  $bdir = Join-Path $root ("tools\_patch_backup\" + $tag + "\" + (Get-Date -Format "yyyyMMdd-HHmmss"))
  EnsureDir $bdir
  $dst = Join-Path $bdir ((Split-Path -Leaf $file) -replace "[:\\\/]", "_")
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

$target = Join-Path $root "src\components\eco\ReceiptShareBar.tsx"
if (!(Test-Path -LiteralPath $target)) { throw ("target_not_found: " + $target) }

$raw = Get-Content -LiteralPath $target -Raw -Encoding UTF8
$hasDef = ($raw -match "(?m)^\s*(export\s+)?(async\s+)?function\s+eco28_shareCard\b") -or ($raw -match "(?m)^\s*(export\s+)?const\s+eco28_shareCard\s*=")
$hasCall = ($raw -match "\beco28_shareCard\s*\(")

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportDir = Join-Path $root "reports"; EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-194-fix-receiptsharebar-sharecard-" + $stamp + ".md")
$r = @()
$r += "# eco-step-194 — fix ReceiptShareBar eco28_shareCard — " + $stamp
$r += ""
$r += "## DIAG"
$r += "- alvo: " + $target
$r += "- call eco28_shareCard(): " + $hasCall
$r += "- def eco28_shareCard(): " + $hasDef
$r += ""

if (-not $hasDef) {
  $backup = BackupFile $target "eco-step-194"

  $linesFile = $raw -split "`n"
  $insertAt = -1
  for ($i = 0; $i -lt $linesFile.Length; $i++) {
    if ($linesFile[$i] -match "^\s*export\s+default\s+function\s+") { $insertAt = $i; break }
    if ($linesFile[$i] -match "^\s*export\s+function\s+") { $insertAt = $i; break }
    if ($linesFile[$i] -match "^\s*function\s+ReceiptShareBar\b") { $insertAt = $i; break }
  }
  if ($insertAt -lt 0) {
    $lastImport = -1
    for ($i = 0; $i -lt $linesFile.Length; $i++) { if ($linesFile[$i] -match "^\s*import\s+") { $lastImport = $i } }
    if ($lastImport -ge 0) { $insertAt = $lastImport + 1 } else { $insertAt = 0 }
  }

  $block = @(
    ""
    "// ECO_STEP28_HELPER_SHARECARD_START"
    "async function eco28_shareCard(code?: string, format: ""3x4"" | ""1x1"" = ""3x4""): Promise<boolean> { "
    "  if (typeof window === ""undefined"") return false;"
    "  const c = String(code || """");"
    "  if (!c) return false;"
    "  const url = ""/api/share/receipt-card?code="" + encodeURIComponent(c) + ""&format="" + format;"
    "  try {"
    "    const res = await fetch(url, { cache: ""no-store"" });"
    "    if (!res.ok) throw new Error(""fetch_failed"");"
    "    const blob = await res.blob();"
    "    const ext = (blob.type && blob.type.indexOf(""png"") >= 0) ? ""png"" : ""bin"";"
    "    const file = new File([blob], ""eco-recibo-"" + c + ""-"" + format + ""."" + ext, { type: blob.type || ""application/octet-stream"" });"
    "    const nav: any = (typeof navigator !== ""undefined"") ? (navigator as any) : null;"
    "    if (nav && typeof nav.share === ""function"") {"
    "      const can = (typeof nav.canShare === ""function"") ? nav.canShare({ files: [file] }) : true;"
    "      if (can) {"
    "        await nav.share({ files: [file], title: ""Recibo ECO"", text: ""Recibo ECO "" + c });"
    "        return true;"
    "      }"
    "    }"
    "    const obj = URL.createObjectURL(blob);"
    "    const a = document.createElement(""a"");"
    "    a.href = obj;"
    "    a.download = file.name;"
    "    document.body.appendChild(a);"
    "    a.click();"
    "    a.remove();"
    "    setTimeout(() => URL.revokeObjectURL(obj), 5000);"
    "    return true;"
    "  } catch (e) {"
    "    console.error(e);"
    "    try { alert(""Nao foi possivel compartilhar agora. Tente baixar o card.""); } catch {}"
    "    return false;"
    "  }"
    "}"
    "// ECO_STEP28_HELPER_SHARECARD_END"
    ""
  )

  $before = @()
  if ($insertAt -gt 0) { $before = $linesFile[0..($insertAt-1)] }
  $after = $linesFile[$insertAt..($linesFile.Length-1)]
  $new = @($before + $block + $after) -join "`n"
  WriteUtf8NoBom $target $new
  $r += "## PATCH"
  $r += "- inseriu funcao eco28_shareCard (def real) antes do componente"
  $r += "- backup: " + $backup
} else {
  $r += "## PATCH"
  $r += "- [SKIP] eco28_shareCard ja estava definida (def real encontrada)"
}

$r += ""
$r += "## VERIFY"
$r += "- rode: npm run build"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if ($OpenReport) { try { Start-Process $reportPath | Out-Null } catch {} }
Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "npm run build"