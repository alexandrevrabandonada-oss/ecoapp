param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$path, [string]$content){
  [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$file, [string]$bakRoot){
  if(!(Test-Path -LiteralPath $file)){ return $null }
  EnsureDir $bakRoot
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakRoot ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}
function RunCmd([string]$label, [scriptblock]$sb, [ref]$out){
  $out.Value += ("### " + $label + "`n~~~`n")
  try {
    $o = (& $sb 2>&1 | Out-String).TrimEnd()
    if($o){ $out.Value += ($o + "`n") }
  } catch {
    $out.Value += ("[ERR] " + $_.Exception.Message + "`n")
  }
  $out.Value += "~~~`n`n"
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

EnsureDir "reports"
EnsureDir "tools\_patch_backup\eco-step-169"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-169-fix-pickuprequests-privacy-scope-" + $stamp + ".md")

$target = "src\app\api\pickup-requests\route.ts"
if(!(Test-Path -LiteralPath $target)){ throw ("missing: " + $target) }

$raw = Get-Content -LiteralPath $target -Raw
$patchLog = ""
$verify = ""

$markerStart = "// ECO_PICKUP_RECEIPT_PRIVACY_START"
$markerEnd   = "// ECO_PICKUP_RECEIPT_PRIVACY_END"

# acha GET + param
$mGet = [regex]::Match($raw, '(?s)export\s+async\s+function\s+GET\s*\(\s*(\w+)\s*:\s*[^)]*\)\s*\{')
if(!$mGet.Success){
  throw "Nao achei export async function GET(<param>: ...){ em src/app/api/pickup-requests/route.ts"
}
$param = $mGet.Groups[1].Value
if([string]::IsNullOrWhiteSpace($param)){ $param = "req" }

# pos do brace do GET
$posBrace = $mGet.Index + $mGet.Value.LastIndexOf("{")

$posMarker = $raw.IndexOf($markerStart)

$patchLog += ("[DIAG] GET param = " + $param + "`n")
$patchLog += ("[DIAG] markerStart pos = " + $posMarker + " ; GET { pos = " + $posBrace + "`n")

$changed = $false

if($posMarker -ge 0){
  if($posMarker -lt $posBrace){
    # bloco está antes do GET (escopo errado) -> extrai e move para dentro do GET
    $posEnd = -1
    $posEndMarker = $raw.IndexOf($markerEnd, $posMarker)
    if($posEndMarker -ge 0){
      # inclui linha do end marker
      $nl = $raw.IndexOf("`n", $posEndMarker)
      if($nl -ge 0){ $posEnd = $nl + 1 } else { $posEnd = $raw.Length }
    } else {
      # se não tiver end marker, corta até o próximo "export async function" (normalmente o GET)
      $tail = $raw.Substring($posMarker)
      $mNext = [regex]::Match($tail, '(?m)^\s*export\s+async\s+function\s+')
      if($mNext.Success){
        $posEnd = $posMarker + $mNext.Index
      } else {
        $posEnd = $raw.Length
      }
    }

    $block = $raw.Substring($posMarker, ($posEnd - $posMarker)).TrimEnd()

    # remove do lugar antigo
    $delta = ($posEnd - $posMarker)
    $raw2 = $raw.Remove($posMarker, $delta)

    # ajusta brace do GET porque removemos texto antes dele
    $posBrace2 = $posBrace - $delta

    # indent + normaliza ecoIsOperator(param)
    $lines = $block -split "(`r`n|`n|`r)"
    $ind = @()
    foreach($ln in $lines){ $ind += ("  " + $ln) }
    $blockIndented = ($ind -join "`n")
    $blockIndented = [regex]::Replace($blockIndented, 'ecoIsOperator\(\s*\w+\s*\)', ('ecoIsOperator(' + $param + ')'))

    # garante newline antes/depois
    $insert = "`n" + $blockIndented + "`n"

    $raw3 = $raw2.Insert($posBrace2 + 1, $insert)

    $raw = $raw3
    $changed = $true
    $patchLog += "[OK] moved privacy block into GET scope`n"
  } else {
    # já está dentro do GET (ou depois) -> só normaliza o param no ecoIsOperator(...)
    $before = $raw
    $raw = [regex]::Replace($raw, 'ecoIsOperator\(\s*\w+\s*\)', ('ecoIsOperator(' + $param + ')'))
    if($raw -ne $before){
      $changed = $true
      $patchLog += "[OK] normalized ecoIsOperator(...) param`n"
    } else {
      $patchLog += "[SKIP] ecoIsOperator(...) already normalized`n"
    }
  }
} else {
  # não achou marker: ainda assim normaliza qualquer ecoIsOperator(request) perdido
  $before = $raw
  $raw = [regex]::Replace($raw, 'ecoIsOperator\(\s*request\s*\)', ('ecoIsOperator(' + $param + ')'))
  if($raw -ne $before){
    $changed = $true
    $patchLog += "[OK] fixed ecoIsOperator(request) -> ecoIsOperator(" + $param + ")`n"
  } else {
    $patchLog += "[SKIP] marker not found; no change`n"
  }
}

if($changed){
  $bk = BackupFile $target "tools\_patch_backup\eco-step-169"
  WriteUtf8NoBom $target $raw
  $patchLog += ("[OK] wrote: " + $target + "`n")
  if($bk){ $patchLog += ("     backup: " + $bk + "`n") }
} else {
  $patchLog += "[SKIP] no file write`n"
}

RunCmd "npm run build" { npm run build } ([ref]$verify)

$r = @()
$r += ("# eco-step-169 — fix pickup-requests privacy block scope — " + $stamp)
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