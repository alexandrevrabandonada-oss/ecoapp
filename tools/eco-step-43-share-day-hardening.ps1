$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ EnsureDir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}
function BackupFile([string]$path){
  if(!(Test-Path -LiteralPath $path)){ return $null }
  EnsureDir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}
function FindFilesContainingSimple([string]$root, [string]$needle){
  if(!(Test-Path -LiteralPath $root)){ return @() }
  $hits = @()
  $files = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @(".ts",".tsx",".js",".jsx") }
  foreach($f in $files){
    try {
      $raw = Get-Content -LiteralPath $f.FullName -Raw
      if($raw -and $raw.Contains($needle)){ $hits += $f.FullName }
    } catch {}
  }
  return $hits
}

$rep = NewReport "eco-step-43-share-day-hardening"
$log = @()
$log += "# ECO — STEP 43 — Share Day Hardening"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  # -------------------------
  # DIAG/PATCH 1) eliminar bug: /s/dia/ virando regex
  # -------------------------
  $badLine = "const ecoDayPublicSharePath = () => /s/dia/;"
  $replacement = "const ecoDayPublicSharePath = () => `/s/dia/${encodeURIComponent(routeDay)}`;"

  $hits = FindFilesContainingSimple "." $badLine
  $log += "## DIAG — ocorrências do bug (regex /s/dia/)"
  if($hits.Count -eq 0){
    $log += "- OK: nenhuma ocorrência encontrada."
  } else {
    $log += ("- Encontradas {0} ocorrências:" -f $hits.Count)
    foreach($h in $hits){ $log += ("  - {0}" -f $h) }
  }
  $log += ""

  if($hits.Count -gt 0){
    foreach($file in $hits){
      $bk = BackupFile $file
      $txt = Get-Content -LiteralPath $file -Raw
      $txt2 = $txt.Replace($badLine, $replacement)
      if($txt2 -ne $txt){
        WriteUtf8NoBom $file $txt2
        $log += "## PATCH — fix regex"
        $log += ("Arquivo: {0}" -f $file)
        $log += ("Backup : {0}" -f $bk)
        $log += "- OK: linha substituída."
        $log += ""
      } else {
        $log += "## PATCH — fix regex"
        $log += ("Arquivo: {0}" -f $file)
        $log += ("Backup : {0}" -f $bk)
        $log += "- INFO: sem mudança (conteúdo igual)."
        $log += ""
      }
    }
  }

  # -------------------------
  # PATCH 2) garantir /api/share/route-day-card (sem any)
  # -------------------------
  $route = "src/app/api/share/route-day-card/route.ts"
  EnsureDir (Split-Path -Parent $route)
  $bkR = BackupFile $route

  $log += "## PATCH — /api/share/route-day-card"
  $log += ("Arquivo: {0}" -f $route)
  $log += ("Backup : {0}" -f ($(if($bkR){$bkR}else{"(novo)"})))
  $log += ""

  $routeLines = @(
    'import { ImageResponse } from "next/og";',
    '',
    'export const runtime = "edge";',
    '',
    'function safeDay(input: string | null): string {',
    '  const s = String(input || "").trim();',
    '  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;',
    '  return "2025-01-01";',
    '}',
    '',
    'function sizeFor(format: string | null) {',
    '  const f = String(format || "").toLowerCase();',
    '  if (f === "1x1") return { w: 1080, h: 1080, label: "1:1" as const };',
    '  return { w: 1080, h: 1350, label: "3:4" as const };',
    '}',
    '',
    'export async function GET(req: Request) {',
    '  try {',
    '    const { searchParams } = new URL(req.url);',
    '    const day = safeDay(searchParams.get("day"));',
    '    const fmt = sizeFor(searchParams.get("format"));',
    '',
    '    const bg = "#0b0b0b";',
    '    const yellow = "#ffd400";',
    '    const red = "#ff3b30";',
    '    const off = "#f5f5f5";',
    '    const gray = "#bdbdbd";',
    '',
    '    return new ImageResponse(',
    '      (',
    '        <div',
    '          style={{',
    '            width: "100%",',
    '            height: "100%",',
    '            display: "flex",',
    '            flexDirection: "column",',
    '            background: bg,',
    '            color: off,',
    '            padding: 64,',
    '            boxSizing: "border-box",',
    '            fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Helvetica Neue, Arial",',
    '            border: `10px solid ${yellow}`,',
    '          }}',
    '        >',
    '          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>',
    '            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>',
    '              <div style={{ fontSize: 22, letterSpacing: 2, color: gray }}>#ECO — Escutar • Cuidar • Organizar</div>',
    '              <div style={{ fontSize: 64, fontWeight: 900, lineHeight: 1.0 }}>',
    '                FECHAMENTO',
    '                <span style={{ color: yellow }}> DO DIA</span>',
    '              </div>',
    '              <div style={{ fontSize: 42, fontWeight: 800, color: off }}>{day}</div>',
    '            </div>',
    '',
    '            <div',
    '              style={{',
    '                width: 120,',
    '                height: 120,',
    '                borderRadius: 999,',
    '                border: `8px solid ${yellow}`,',
    '                display: "flex",',
    '                alignItems: "center",',
    '                justifyContent: "center",',
    '                fontSize: 34,',
    '                fontWeight: 900,',
    '                color: yellow,',
    '              }}',
    '            >',
    '              {fmt.label}',
    '            </div>',
    '          </div>',
    '',
    '          <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "flex-end", gap: 18 }}>',
    '            <div style={{ display: "flex", gap: 14, flexWrap: "wrap" }}>',
    '              <div style={{ padding: "10px 14px", borderRadius: 999, border: `2px solid ${gray}`, fontSize: 20 }}>Recibo é lei</div>',
    '              <div style={{ padding: "10px 14px", borderRadius: 999, border: `2px solid ${gray}`, fontSize: 20 }}>Cuidado é coletivo</div>',
    '              <div style={{ padding: "10px 14px", borderRadius: 999, border: `2px solid ${gray}`, fontSize: 20 }}>Trabalho digno no centro</div>',
    '            </div>',
    '',
    '            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>',
    '              <div style={{ fontSize: 22, opacity: 0.9, color: gray }}>Compartilhe o fechamento: /s/dia/{day}</div>',
    '              <div style={{ fontSize: 18, color: red, opacity: 0.95 }}>Sem greenwashing • Abandono × Cuidado</div>',
    '            </div>',
    '          </div>',
    '        </div>',
    '      ),',
    '      {',
    '        width: fmt.w,',
    '        height: fmt.h,',
    '        headers: {',
    '          "cache-control": "public, max-age=0, s-maxage=3600, stale-while-revalidate=86400",',
    '        },',
    '      }',
    '    );',
    '  } catch (err: unknown) {',
    '    const msg = err instanceof Error ? err.message : "unknown";',
    '    return new Response("route-day-card error: " + msg, { status: 500 });',
    '  }',
    '}'
  )
  $routeTxt = $routeLines -join "`n"
  WriteUtf8NoBom $route $routeTxt
  $log += "- OK: route-day-card escrito (ImageResponse)."
  $log += ""

  # -------------------------
  # PATCH 3) garantir smoke share-day
  # -------------------------
  $smokePath = "tools/eco-smoke-share-day.ps1"
  $bkS = BackupFile $smokePath

  $log += "## PATCH — tools/eco-smoke-share-day.ps1"
  $log += ("Arquivo: {0}" -f $smokePath)
  $log += ("Backup : {0}" -f ($(if($bkS){$bkS}else{"(novo)"})))
  $log += ""

  $smokeLines = @(
    '$ErrorActionPreference = "Stop"',
    '',
    'Write-Host "== ECO SMOKE — SHARE DAY ==" -ForegroundColor Cyan',
    '$BaseUrl = "http://localhost:3000"',
    '$today = (Get-Date -Format "yyyy-MM-dd")',
    '',
    '$paths = @(',
    '  "/s/dia",',
    '  "/s/dia/$today",',
    '  "/api/share/route-day-card?day=$today&format=3x4",',
    '  "/api/share/route-day-card?day=$today&format=1x1",',
    '  "/operador/triagem"',
    ')',
    '',
    'foreach($p in $paths){',
    '  $url = $BaseUrl + $p',
    '  try {',
    '    $res = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing',
    '    $sc = [int]$res.StatusCode',
    '    if($sc -ge 200 -and $sc -lt 300){',
    '      Write-Host ("OK {0} -> {1}" -f $sc, $p) -ForegroundColor Green',
    '    } else {',
    '      Write-Host ("FAIL {0} -> {1}" -f $sc, $p) -ForegroundColor Red',
    '      exit 1',
    '    }',
    '  } catch {',
    '    Write-Host ("ERR -> {0}" -f $p) -ForegroundColor Red',
    '    Write-Host ($_.Exception.Message) -ForegroundColor DarkRed',
    '    exit 1',
    '  }',
    '}',
    '',
    'Write-Host "OK: smoke share day concluído" -ForegroundColor Green'
  )
  $smokeTxt = $smokeLines -join "`n"
  WriteUtf8NoBom $smokePath $smokeTxt
  $log += "- OK: smoke escrito/atualizado."
  $log += ""

  # -------------------------
  # REPORT + NEXT
  # -------------------------
  $log += "## VERIFY"
  $log += "1) CTRL+C ; npm run dev"
  $log += "2) Abra /s/dia"
  $log += "3) Abra /s/dia/$(Get-Date -Format yyyy-MM-dd)"
  $log += "4) Abra /api/share/route-day-card?day=YYYY-MM-DD&format=3x4"
  $log += "5) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke-share-day.ps1"
  $log += ""

  WriteUtf8NoBom $rep ($log -join "`n")

  Write-Host ("✅ STEP 43 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
  Write-Host "1) CTRL+C ; npm run dev" -ForegroundColor Yellow
  Write-Host "2) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke-share-day.ps1" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}