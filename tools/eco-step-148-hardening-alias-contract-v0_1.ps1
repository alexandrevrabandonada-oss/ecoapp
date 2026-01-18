param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

function NowStamp(){ return (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }

function BackupFile([string]$src, [string]$backupRoot){
  if(!(Test-Path $src)){ return }
  $full = (Resolve-Path $src).Path
  $cwd = (Get-Location).Path
  $rel = $full.Substring($cwd.Length).TrimStart("\","/")
  $dst = Join-Path $backupRoot $rel
  $dstDir = Split-Path -Parent $dst
  EnsureDir $dstDir
  Copy-Item -Force $src $dst
}

function WriteLinesUtf8NoBom([string]$path, [string[]]$lines){
  $content = ($lines -join "`n")
  WriteUtf8NoBom $path $content
}

function EnsureRuntimeNodeJs([string]$file){
  if(!(Test-Path $file)){ return @{ ok=$false; reason="missing" } }
  $raw = Get-Content $file -Raw

  $changed = $false

  # troca edge -> nodejs
  $reEdge = 'export\s+const\s+runtime\s*=\s*["'']edge["'']\s*;?'
  if ($raw -match $reEdge) {
    $raw = [regex]::Replace($raw, $reEdge, 'export const runtime = "nodejs";')
    $changed = $true
  }

  # se não tiver runtime, injeta no topo
  if ($raw -notmatch 'export\s+const\s+runtime\s*=') {
    $raw = "export const runtime = `"nodejs`";`n`n" + $raw
    $changed = $true
  }

  if($changed){
    WriteUtf8NoBom $file $raw
    return @{ ok=$true; changed=$true; reason="patched" }
  }

  return @{ ok=$true; changed=$false; reason="already_ok" }
}

function TryHttp([string]$url){
  try {
    $r = Invoke-WebRequest -Uri $url -Method GET -Headers @{ Accept="application/json" } -UseBasicParsing
    $txt = $r.Content
    return @{ ok=$true; status=[int]$r.StatusCode; body=$txt }
  } catch {
    return @{ ok=$false; status=$null; err=$_.Exception.Message }
  }
}

if(!(Test-Path "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$stamp = NowStamp
EnsureDir "reports"
EnsureDir "tools\_patch_backup"
$backupRoot = Join-Path "tools\_patch_backup" ("eco-step-148-" + $stamp)
EnsureDir $backupRoot

$reportPath = Join-Path "reports" ("eco-step-148-hardening-alias-contract-" + $stamp + ".md")

# --- targets
$aliasList2 = "src\app\api\eco\points\list2\route.ts"
$aliasPoints2 = "src\app\api\eco\points2\route.ts"
$aliasPointDetail = "src\app\api\eco\point\detail\route.ts"

$failMap = "src\app\api\eco\points\map\route.ts"
$failStats = "src\app\api\eco\points\stats\route.ts"
$failMural = "src\app\api\eco\mural\list\route.ts"

$changedFiles = @()

# --- backup originals (se existirem)
$toBackup = @($aliasList2,$aliasPoints2,$aliasPointDetail,$failMap,$failStats,$failMural)
foreach($f in $toBackup){ BackupFile $f $backupRoot }

# --- PATCH 1: Aliases -> canônico (proxy)
if(Test-Path $aliasList2){
  $lines = @(
    'import { NextResponse } from "next/server";',
    '',
    'export const runtime = "nodejs";',
    '',
    'export async function GET(req: Request) {',
    '  const url = new URL(req.url);',
    '  url.pathname = "/api/eco/points/list";',
    '  const res = await fetch(url.toString(), {',
    '    method: "GET",',
    '    headers: req.headers,',
    '    cache: "no-store",',
    '  });',
    '  const body = await res.text();',
    '  return new NextResponse(body, {',
    '    status: res.status,',
    '    headers: { "content-type": "application/json; charset=utf-8" },',
    '  });',
    '}'
  )
  WriteLinesUtf8NoBom $aliasList2 $lines
  $changedFiles += $aliasList2
}

if(Test-Path $aliasPoints2){
  $lines = @(
    'import { NextResponse } from "next/server";',
    '',
    'export const runtime = "nodejs";',
    '',
    'export async function GET(req: Request) {',
    '  const url = new URL(req.url);',
    '  url.pathname = "/api/eco/points/list";',
    '  const res = await fetch(url.toString(), {',
    '    method: "GET",',
    '    headers: req.headers,',
    '    cache: "no-store",',
    '  });',
    '  const body = await res.text();',
    '  return new NextResponse(body, {',
    '    status: res.status,',
    '    headers: { "content-type": "application/json; charset=utf-8" },',
    '  });',
    '}'
  )
  WriteLinesUtf8NoBom $aliasPoints2 $lines
  $changedFiles += $aliasPoints2
}

if(Test-Path $aliasPointDetail){
  $lines = @(
    'import { NextResponse } from "next/server";',
    '',
    'export const runtime = "nodejs";',
    '',
    '// alias canônico: /api/eco/points/get?id=...',
    'export async function GET(req: Request) {',
    '  const url = new URL(req.url);',
    '  url.pathname = "/api/eco/points/get";',
    '  const res = await fetch(url.toString(), {',
    '    method: "GET",',
    '    headers: req.headers,',
    '    cache: "no-store",',
    '  });',
    '  const body = await res.text();',
    '  return new NextResponse(body, {',
    '    status: res.status,',
    '    headers: { "content-type": "application/json; charset=utf-8" },',
    '  });',
    '}'
  )
  WriteLinesUtf8NoBom $aliasPointDetail $lines
  $changedFiles += $aliasPointDetail
}

# --- PATCH 2: runtime nodejs nos 3 endpoints que estavam 503
$rt1 = EnsureRuntimeNodeJs $failMap
$rt2 = EnsureRuntimeNodeJs $failStats
$rt3 = EnsureRuntimeNodeJs $failMural
if($rt1.ok -and $rt1.changed){ $changedFiles += $failMap }
if($rt2.ok -and $rt2.changed){ $changedFiles += $failStats }
if($rt3.ok -and $rt3.changed){ $changedFiles += $failMural }

# --- VERIFY: lint/build (best-effort)
$verify = @()
function RunStep([string]$label, [string]$cmd){
  $verify += ""
  $verify += ("### " + $label)
  try {
    $out = & powershell -NoProfile -Command $cmd 2>&1
    $verify += "```"
    $verify += ($out | Out-String)
    $verify += "```"
  } catch {
    $verify += ("(erro ao rodar: " + $_.Exception.Message + ")")
  }
}

RunStep "npm run lint" "npm run lint"
RunStep "npm run build" "npm run build"

# --- SMOKE (best-effort): precisa dev em localhost:3000
$base = "http://localhost:3000"
$smokeTargets = @(
  @{ name="points_list"; url=($base + "/api/eco/points/list") },
  @{ name="points_list2"; url=($base + "/api/eco/points/list2") },
  @{ name="points2"; url=($base + "/api/eco/points2") },
  @{ name="points_map"; url=($base + "/api/eco/points/map") },
  @{ name="points_stats"; url=($base + "/api/eco/points/stats") },
  @{ name="mural_list"; url=($base + "/api/eco/mural/list") }
)

$smoke = @()
foreach($t in $smokeTargets){
  $res = TryHttp $t.url
  $smoke += ""
  $smoke += ("### " + $t.name)
  if($res.ok){
    $smoke += ("- status: " + $res.status)
    $smoke += "```json"
    # limita corpo pra não explodir report
    $body = $res.body
    if($body.Length -gt 4000){ $body = $body.Substring(0,4000) + "...(trunc)" }
    $smoke += $body
    $smoke += "```"
  } else {
    $smoke += ("- error: " + $res.err)
  }
}

# --- REPORT
$r = @()
$r += ("# eco-step-148 — hardening (alias → canônico + runtime nodejs) — " + $stamp)
$r += ""
$r += "## O que este patch faz"
$r += "- /api/eco/points/list2 → proxy canônico /api/eco/points/list"
$r += "- /api/eco/points2 → proxy canônico /api/eco/points/list"
$r += "- /api/eco/point/detail → proxy canônico /api/eco/points/get"
$r += "- Força runtime = nodejs em endpoints que estavam 503: points/map, points/stats, mural/list"
$r += ""
$r += "## Backup"
$r += ("- " + (Resolve-Path $backupRoot).Path)
$r += ""
$r += "## Arquivos alterados"
if($changedFiles.Count -eq 0){ $r += "- (nenhum)" } else { foreach($f in $changedFiles){ $r += ("- " + $f) } }
$r += ""
$r += "## VERIFY"
$r += $verify
$r += ""
$r += "## SMOKE (best-effort, requer dev em localhost:3000)"
$r += $smoke

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }