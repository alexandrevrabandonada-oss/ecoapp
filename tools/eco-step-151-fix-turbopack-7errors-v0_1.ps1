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
function WriteLines([string]$file, [string[]]$lines){
  $dir = Split-Path -Parent $file
  if($dir){ EnsureDir $dir }
  WriteUtf8NoBom $file (($lines -join "`n") + "`n")
}

function UpdateFile([string]$file, [scriptblock]$transform, [string]$label, [ref]$log){
  if(!(Test-Path -LiteralPath $file)){
    $log.Value += ("[MISS] " + $file + " (" + $label + ")`n")
    return
  }
  $raw = Get-Content -LiteralPath $file -Raw
  $new = & $transform $raw
  if($null -eq $new -or $new -eq $raw){
    $log.Value += ("[SKIP] " + $file + " (" + $label + ": no change)`n")
    return
  }
  $bak = BackupFile $file "tools\_patch_backup\eco-step-151"
  WriteUtf8NoBom $file $new
  $log.Value += ("[OK]   " + $file + " (" + $label + ")`n")
  if($bak){ $log.Value += ("       backup: " + $bak + "`n") }
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

if(!(Test-Path -LiteralPath "package.json")){
  throw "Rode na raiz do repo (onde tem package.json)."
}

EnsureDir "reports"
EnsureDir "tools\_patch_backup\eco-step-151"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-151-fix-turbopack-7errors-" + $stamp + ".md")

$patchLog = ""
$verify = ""

# ------------------------------------------------------------
# 1) src/app/api/eco/mutirao/finish/route.ts  (keys array quebrada)
# ------------------------------------------------------------
UpdateFile "src\app\api\eco\mutirao\finish\route.ts" {
  param($raw)
  # Normaliza QUALQUER "const keys = [...]" dentro de findLinkedPointId para um array de strings válido
  $replacement = 'const keys = ["pointId","criticalPointId","ecoPointId","ecoCriticalPointId","pontoId","pontoCriticoId"];'
  $raw2 = [regex]::Replace($raw, 'const\s+keys\s*=\s*\[[^\]]*\]\s*;', $replacement)
  return $raw2
} "fix keys array (strings)" ([ref]$patchLog)

# ------------------------------------------------------------
# 2) confirm/replicar/support: randId(" \n c \n ") -> randId("c")
# ------------------------------------------------------------
function FixRandIdBroken([string]$raw){
  return [regex]::Replace(
    $raw,
    'randId\("\s*\r?\n\s*([a-zA-Z])\s*\r?\n\s*"\)',
    'randId("$1")'
  )
}

UpdateFile "src\app\api\eco\points\confirm\route.ts" {
  param($raw)
  return FixRandIdBroken $raw
} "fix randId string (confirm)" ([ref]$patchLog)

UpdateFile "src\app\api\eco\points\replicar\route.ts" {
  param($raw)
  return FixRandIdBroken $raw
} "fix randId string (replicar)" ([ref]$patchLog)

UpdateFile "src\app\api\eco\points\support\route.ts" {
  param($raw)
  return FixRandIdBroken $raw
} "fix randId string (support)" ([ref]$patchLog)

# ------------------------------------------------------------
# 3) MuralTopBarClient.tsx: reescreve sem } sobrando
# ------------------------------------------------------------
$muralTop = "src\app\eco\mural-acoes\_components\MuralTopBarClient.tsx"
if(Test-Path -LiteralPath $muralTop){ BackupFile $muralTop "tools\_patch_backup\eco-step-151" | Out-Null }

WriteLines $muralTop @(
  '"use client";',
  'import Link from "next/link";',
  'import { usePathname } from "next/navigation";',
  '',
  'export default function MuralTopBarClient(){',
  '  const pathname = usePathname();',
  '  const tabs = [',
  '    { href: "/eco/mural", label: "Mural" },',
  '    { href: "/eco/mural-acoes", label: "Acoes" },',
  '    { href: "/eco/pontos", label: "Pontos" },',
  '    { href: "/eco/mutiroes", label: "Mutiroes" },',
  '  ];',
  '  return (',
  '    <div className="mb-4 flex flex-wrap gap-2">',
  '      {tabs.map((t) => {',
  '        const active = pathname ? pathname.startsWith(t.href) : false;',
  '        const cls = "rounded-full px-3 py-1 text-sm " + (active ? "bg-amber-400 text-black" : "border border-neutral-800 text-neutral-200");',
  '        return (',
  '          <Link key={t.href} href={t.href} className={cls}>{t.label}</Link>',
  '        );',
  '      })}',
  '    </div>',
  '  );',
  '}'
)
$patchLog += "[OK]   reescrito: $muralTop (remove } sobrando)`n"

# ------------------------------------------------------------
# 4) pedidos/page.tsx: ""GET ..." -> "GET ..."
# ------------------------------------------------------------
UpdateFile "src\app\pedidos\page.tsx" {
  param($raw)
  $raw2 = [regex]::Replace(
    $raw,
    'throw\s+new\s+Error\(\s*json\?\.\s*error\s*\?\?\s*""GET\s+\/api\/pickup-requests\s+falhou"\s*\)',
    'throw new Error(json?.error ?? "GET /api/pickup-requests falhou")'
  )
  # Se não bater, faz fallback: reescreve qualquer "?? ""GET" para '?? "GET'
  $raw2 = [regex]::Replace($raw2, '\?\?\s*""GET', '?? "GET')
  return $raw2
} "fix string aspas duplas (pedidos)" ([ref]$patchLog)

# ------------------------------------------------------------
# 5) recibo-client.tsx: mensagem sem aspas em throw new Error(...)
# ------------------------------------------------------------
$reciboClient = "src\app\recibo\[code]\recibo-client.tsx"
UpdateFile $reciboClient {
  param($raw)
  # Corrige o caso exato do erro do build (GET /api/receipts... sem aspas)
  $raw2 = [regex]::Replace(
    $raw,
    'throw\s+new\s+Error\(\s*json\?\.\s*error\s*\?\?\s*GET\s+\/api\/receipts\?code[^\)]*\)',
    'throw new Error(json?.error ?? "GET /api/receipts falhou")'
  )
  # Fallback: se ainda houver "?? GET /api/receipts" sem aspas
  $raw2 = [regex]::Replace($raw2, '\?\?\s*GET\s+\/api\/receipts', '?? "GET /api/receipts')
  # Se o fallback abriu aspas, fecha antes do ); (bem conservador)
  $raw2 = [regex]::Replace($raw2, '("GET \/api\/receipts[^"\r\n;]*)(\)\s*;)', '$1")$2')
  return $raw2
} "fix throw message (recibo-client)" ([ref]$patchLog)

# ------------------------------------------------------------
# VERIFY: build
# ------------------------------------------------------------
RunCmd "npm run build" { npm run build } 340 ([ref]$verify)

# REPORT
$r = @()
$r += ("# eco-step-151 — fix Turbopack 7 errors — " + $stamp)
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