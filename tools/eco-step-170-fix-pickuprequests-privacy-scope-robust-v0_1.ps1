param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ return }; if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file, [string]$bakRoot){
  if(!(Test-Path -LiteralPath $file)){ return $null }
  EnsureDir $bakRoot
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakRoot ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}
function RunCmd([string]$label, [scriptblock]$sb, [int]$maxLines, [ref]$out){
  $out.Value += ("### " + $label + "`n~~~`n")
  try {
    $res = (& $sb 2>&1 | Out-String)
    if($maxLines -gt 0){
      $lines = $res -split "(`r`n|`n|`r)"
      if($lines.Count -gt $maxLines){
        $res = (($lines | Select-Object -First $maxLines) -join "`n") + "`n... (truncado)"
      }
    }
    $out.Value += ($res.TrimEnd() + "`n")
  } catch {
    $out.Value += ("[ERR] " + $_.Exception.Message + "`n")
  }
  $out.Value += "~~~`n`n"
}

function FindMatchingBrace([string]$text, [int]$openIndex){
  $depth = 0
  for($i=$openIndex; $i -lt $text.Length; $i++){
    $ch = $text[$i]
    if($ch -eq "{"){ $depth++ }
    elseif($ch -eq "}"){
      $depth--
      if($depth -eq 0){ return $i }
    }
  }
  return -1
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

EnsureDir "reports"
EnsureDir "tools\_patch_backup\eco-step-170"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-170-fix-pickuprequests-privacy-scope-robust-" + $stamp + ".md")

$target = "src\app\api\pickup-requests\route.ts"
if(!(Test-Path -LiteralPath $target)){ throw ("missing: " + $target) }

$raw = Get-Content -LiteralPath $target -Raw

$markerStart = "// ECO_PICKUP_RECEIPT_PRIVACY_START"
$markerEnd   = "// ECO_PICKUP_RECEIPT_PRIVACY_END"

$patchLog = ""
$verify = ""

# --- detect GET handler param name (function or const/arrow)
$param = $null
$m = $null

$patterns = @(
  '(?s)export\s+async\s+function\s+GET\s*\(\s*(\w+)',
  '(?s)export\s+function\s+GET\s*\(\s*(\w+)',
  '(?s)export\s+const\s+GET\s*=\s*async\s*\(\s*(\w+)',
  '(?s)export\s+const\s+GET\s*=\s*\(\s*(\w+)'
)

foreach($p in $patterns){
  $m = [regex]::Match($raw, $p)
  if($m.Success){ $param = $m.Groups[1].Value; break }
}

if([string]::IsNullOrWhiteSpace($param)){ $param = "req" }
$patchLog += ("[DIAG] GET param detected: " + $param + "`n")

# --- find GET opening brace
$openBrace = -1
if($m -and $m.Success){
  $after = $m.Index
  $openBrace = $raw.IndexOf("{", $after)
}
if($openBrace -lt 0){
  throw "Nao consegui achar a chave de abertura do handler GET no src/app/api/pickup-requests/route.ts"
}

$closeBrace = FindMatchingBrace $raw $openBrace
if($closeBrace -lt 0){
  throw "Nao consegui achar a chave de fechamento do handler GET (brace matching falhou)."
}

$patchLog += ("[DIAG] GET brace range: " + $openBrace + " .. " + $closeBrace + "`n")

# --- locate privacy block
$posStart = $raw.IndexOf($markerStart)
if($posStart -lt 0){
  $patchLog += "[SKIP] privacy markers not found (no change)`n"
} else {
  $posEndMarker = $raw.IndexOf($markerEnd, $posStart)
  if($posEndMarker -lt 0){
    throw "Achei ECO_PICKUP_RECEIPT_PRIVACY_START mas nao achei ECO_PICKUP_RECEIPT_PRIVACY_END."
  }

  $nl = $raw.IndexOf("`n", $posEndMarker)
  $posEnd = if($nl -ge 0){ $nl + 1 } else { $raw.Length }
  $len = $posEnd - $posStart
  $block = $raw.Substring($posStart, $len).TrimEnd()

  $inside = ($posStart -gt $openBrace) -and ($posStart -lt $closeBrace)

  if($inside){
    # already inside: just normalize ecoIsOperator param
    $before = $raw
    $raw = [regex]::Replace($raw, 'ecoIsOperator\(\s*\w+\s*\)', ('ecoIsOperator(' + $param + ')'))
    if($raw -ne $before){ $patchLog += "[OK] normalized ecoIsOperator(...) inside block`n" } else { $patchLog += "[SKIP] ecoIsOperator already ok`n" }
  } else {
    # remove block from old position
    $raw2 = $raw.Remove($posStart, $len)

    # adjust brace positions if we removed text before them
    if($posStart -lt $openBrace){
      $openBrace -= $len
      $closeBrace -= $len
    } elseif($posStart -lt $closeBrace){
      $closeBrace -= $len
    }

    # indent block + normalize ecoIsOperator(param)
    $lines = $block -split "(`r`n|`n|`r)"
    $ind = @()
    foreach($ln in $lines){ $ind += ("  " + $ln) }
    $blockIndented = ($ind -join "`n")
    $blockIndented = [regex]::Replace($blockIndented, 'ecoIsOperator\(\s*\w+\s*\)', ('ecoIsOperator(' + $param + ')'))

    $insert = "`n" + $blockIndented + "`n"

    # insert right after opening brace of GET
    $raw3 = $raw2.Insert($openBrace + 1, $insert)
    $raw = $raw3

    $patchLog += "[OK] moved privacy block into GET scope and normalized ecoIsOperator(...)`n"
  }

  # also fix any stray ecoIsOperator(request) left anywhere in file
  $raw = [regex]::Replace($raw, 'ecoIsOperator\(\s*request\s*\)', ('ecoIsOperator(' + $param + ')'))
}

# --- write if changed
$orig = Get-Content -LiteralPath $target -Raw
if($raw -ne $orig){
  $bk = BackupFile $target "tools\_patch_backup\eco-step-170"
  WriteUtf8NoBom $target $raw
  $patchLog += ("[OK] wrote: " + $target + "`n")
  if($bk){ $patchLog += ("     backup: " + $bk + "`n") }
} else {
  $patchLog += "[SKIP] no file write (content unchanged)`n"
}

RunCmd "npm run build" { npm run build } 520 ([ref]$verify)

$r = @()
$r += ("# eco-step-170 — fix pickup-requests privacy scope robust — " + $stamp)
$r += ""
$r += "## Patch log"
$r += "~~~"
$r += $patchLog.TrimEnd()
$r += "~~~"
$r += ""
$r += "## VERIFY"
$r += $verify

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] Se o build passar, rode o smoke:"
Write-Host "  pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport"