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

# tenta usar tools/_bootstrap.ps1 (se existir)
$bootstrap = "tools\_bootstrap.ps1"
if(Test-Path -LiteralPath $bootstrap){
  . $bootstrap
}

function ReplaceFunctionBlock([string]$text, [string]$funcName, [string]$replacement, [ref]$found){
  $idx = $text.IndexOf("function " + $funcName)
  if($idx -lt 0){ return $text }

  $braceStart = $text.IndexOf("{", $idx)
  if($braceStart -lt 0){ return $text }

  $depth = 0
  $end = -1
  for($i=$braceStart; $i -lt $text.Length; $i++){
    $ch = $text[$i]
    if($ch -eq "{"){ $depth++ }
    elseif($ch -eq "}"){
      $depth--
      if($depth -eq 0){ $end = $i; break }
    }
  }
  if($end -lt 0){ return $text }

  $found.Value = $true
  $before = $text.Substring(0, $idx)
  $after  = $text.Substring($end + 1)
  return ($before + $replacement + $after)
}

function PatchActorFile([string]$file, [ref]$log){
  if(!(Test-Path -LiteralPath $file)){
    $log.Value += "[SKIP] $file (nao existe)`n"
    return
  }

  $raw0 = Get-Content -LiteralPath $file -Raw
  $raw = $raw0

  # remove import cookies (duas variantes)
  $raw = [regex]::Replace($raw, '(?m)^\s*import\s*\{\s*cookies\s*\}\s*from\s*"next/headers"\s*;\s*\r?\n', '')
  $raw = [regex]::Replace($raw, "(?m)^\s*import\s*\{\s*cookies\s*\}\s*from\s*'next/headers'\s*;\s*\r?\n", '')

  $hasReadCookie = ($raw -match 'function\s+readCookie\s*\(')

  $blockBoth = @(
'function readCookie(req: Request, name: string): string | null {',
'  const h = req.headers.get("cookie") || "";',
'  const parts = h.split(/;\s*/);',
'  for (const p of parts) {',
'    const eq = p.indexOf("=");',
'    if (eq <= 0) continue;',
'    const k = p.slice(0, eq).trim();',
'    if (k !== name) continue;',
'    const v = p.slice(eq + 1);',
'    try { return decodeURIComponent(v); } catch { return v; }',
'  }',
'  return null;',
'}',
'',
'function readActorFromReq(req: Request, body: any): string {',
'  const c1 = readCookie(req, "eco_actor");',
'  const c2 = readCookie(req, "nika_email");',
'  const h = req.headers.get("x-actor");',
'  const b = body && typeof body.actor === "string" ? body.actor : null;',
'  return (h && h.trim()) || (b && b.trim()) || (c1 && c1.trim()) || (c2 && c2.trim()) || "anon";',
'}'
) -join "`n"

  $blockActorOnly = @(
'function readActorFromReq(req: Request, body: any): string {',
'  const c1 = readCookie(req, "eco_actor");',
'  const c2 = readCookie(req, "nika_email");',
'  const h = req.headers.get("x-actor");',
'  const b = body && typeof body.actor === "string" ? body.actor : null;',
'  return (h && h.trim()) || (b && b.trim()) || (c1 && c1.trim()) || (c2 && c2.trim()) || "anon";',
'}'
) -join "`n"

  $wanted = $(if($hasReadCookie){ $blockActorOnly } else { $blockBoth })

  # tenta substituir o bloco inteiro da funcao (brace matching)
  $found = $false
  $raw2 = ReplaceFunctionBlock $raw "readActorFromReq" $wanted ([ref]$found)

  $changed = $false
  if($raw2 -ne $raw){ $raw = $raw2; $changed = $true }

  # fallback: se nao achou readActorFromReq mas tem cookies().get, troca por readCookie(req,...)
  if(-not $found){
    if($raw -match 'cookies\(\)\.get\('){
      if(-not $hasReadCookie){
        # injeta readCookie logo depois dos imports (bem no topo, apos bloco de imports)
        $ins = (@(
'',
'function readCookie(req: Request, name: string): string | null {',
'  const h = req.headers.get("cookie") || "";',
'  const parts = h.split(/;\s*/);',
'  for (const p of parts) {',
'    const eq = p.indexOf("=");',
'    if (eq <= 0) continue;',
'    const k = p.slice(0, eq).trim();',
'    if (k !== name) continue;',
'    const v = p.slice(eq + 1);',
'    try { return decodeURIComponent(v); } catch { return v; }',
'  }',
'  return null;',
'}',
'' ) -join "`n")

        $m = [regex]::Match($raw, '(?s)\A((?:\s*import[^\n]*\r?\n)+)')
        if($m.Success){
          $raw = $m.Groups[1].Value + $ins + $raw.Substring($m.Groups[1].Length)
        } else {
          $raw = $ins + $raw
        }
        $changed = $true
      }

      $rawOld = $raw
      $raw = [regex]::Replace($raw, 'cookies\(\)\.get\(\s*(["''])([^"''\r\n]+)\1\s*\)\s*(\?\.)?\s*value', 'readCookie(req, "$2")')
      if($raw -ne $rawOld){ $changed = $true }

      $log.Value += "[OK]   fallback replace cookies().get(...).value -> readCookie(req, ...) em $file`n"
    } else {
      $log.Value += "[SKIP] $file (readActorFromReq nao encontrado e nao tem cookies().get)`n"
    }
  }

  if($changed -and ($raw -ne $raw0)){
    $bk = BackupFile $file "tools\_patch_backup\eco-step-159"
    WriteUtf8NoBom $file $raw
    $log.Value += "[OK]   patched: $file`n"
    if($bk){ $log.Value += "       backup: $bk`n" }
  } elseif($changed){
    $log.Value += "[SKIP] $file (sem mudanca efetiva)`n"
  } else {
    $log.Value += "[SKIP] $file (no change)`n"
  }
}

function RunCmd([string]$label, [scriptblock]$sb, [ref]$out){
  $out.Value += "### $label`n~~~`n"
  try { $out.Value += ((& $sb 2>&1 | Out-String).TrimEnd() + "`n") }
  catch { $out.Value += ("[ERR] " + $_.Exception.Message + "`n") }
  $out.Value += "~~~`n`n"
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

EnsureDir "reports"
EnsureDir "tools\_patch_backup\eco-step-159"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-159-fix-actor-cookieheader-" + $stamp + ".md")

$patchLog = ""
$verify = ""

$targets = @(
  "src\app\api\eco\points\confirm\route.ts",
  "src\app\api\eco\points\replicar\route.ts",
  "src\app\api\eco\points\support\route.ts"
)

foreach($f in $targets){
  PatchActorFile $f ([ref]$patchLog)
}

RunCmd "npm run build" { npm run build } ([ref]$verify)

$r = @()
$r += ("# eco-step-159 — fix cookies async (cookie header) — " + $stamp)
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