param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p,[string]$c){ [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($false)) }
function ReadRaw([string]$p){ if(!(Test-Path -LiteralPath $p)){ return $null }; Get-Content -LiteralPath $p -Raw -Encoding UTF8 }

function BackupFile([string]$p,[string]$backupDir){
  if(!(Test-Path -LiteralPath $p)){ return "" }
  EnsureDir $backupDir
  $safe = ($p -replace '[:\\\/\[\]]','_')
  $dst = Join-Path $backupDir ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $p -Destination $dst -Force
  return $dst
}

function WriteLines([string]$p,[string[]]$ls){
  $dir = Split-Path -Parent $p
  if($dir){ EnsureDir $dir }
  WriteUtf8NoBom $p (($ls -join "`n") + "`n")
}

function ReplaceRegex([string]$p,[string]$pattern,[string]$replacement,[ref]$log){
  $raw = ReadRaw $p
  if($null -eq $raw){ $log.Value += "[MISS] $p`n"; return $false }
  $re = [regex]::new($pattern,[Text.RegularExpressions.RegexOptions]::Singleline)
  if(-not $re.IsMatch($raw)){ $log.Value += "[SKIP] $p (regex nao achado)`n"; return $false }
  BackupFile $p "tools\_patch_backup" | Out-Null
  $new = $re.Replace($raw,$replacement)
  WriteUtf8NoBom $p $new
  $log.Value += "[OK]   $p (regex)`n"
  return $true
}

function EnsureUseClientFirst([string]$p,[ref]$log){
  $raw = ReadRaw $p
  if($null -eq $raw){ $log.Value += "[MISS] $p`n"; return $false }
  BackupFile $p "tools\_patch_backup" | Out-Null
  $raw = $raw -replace "^\uFEFF",""
  $raw = [regex]::Replace($raw,'^\s*"use client";\s*\r?\n',"",[Text.RegularExpressions.RegexOptions]::Multiline)
  $raw = '"use client";' + "`n" + ($raw.TrimStart())
  WriteUtf8NoBom $p $raw
  $log.Value += "[OK]   $p (use client 1a linha)`n"
  return $true
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

EnsureDir "reports"
EnsureDir "tools\_patch_backup"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-149-fix-compile-blockers-" + $stamp + ".md")
$patchLog = ""

# 1) .eslintignore (para lint parar de varrer backups/reports)
$eslintIgnore = ".eslintignore"
$need = @(".next/","node_modules/","dist/","reports/","tools/_patch_backup/","tools/_db_backup/")
$cur = @()
if(Test-Path -LiteralPath $eslintIgnore){ $cur = Get-Content -LiteralPath $eslintIgnore -Encoding UTF8 }
$out = New-Object System.Collections.Generic.List[string]
foreach($l in $cur){ if($l -and $l.Trim().Length -gt 0){ $out.Add($l.Trim()) } }
foreach($l in $need){ if(-not ($out -contains $l)){ $out.Add($l) } }
WriteLines $eslintIgnore ($out.ToArray())
$patchLog += "[OK]   .eslintignore atualizado`n"

# 2) componente faltante: MuralTopBarClient
$muralTop = "src\app\eco\mural-acoes\_components\MuralTopBarClient.tsx"
if(!(Test-Path -LiteralPath $muralTop)){
  $ls = @(
    '"use client";',
    'import * as React from "react";',
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
    '        return (<Link key={t.href} href={t.href} className={cls}>{t.label}</Link>);',
    '      })}',
    '      }',
    '    </div>',
    '  );',
    '}'
  )
  WriteLines $muralTop $ls
  $patchLog += "[OK]   criado: $muralTop`n"
} else {
  $patchLog += "[SKIP] $muralTop ja existe`n"
}

# 3) "use client" no topo
EnsureUseClientFirst "src\app\eco\mural-acoes\MuralAcoesClient.tsx" ([ref]$patchLog) | Out-Null

# 4) mutirao/finish: remove token invalido "pointId",
ReplaceRegex "src\app\api\eco\mutirao\finish\route.ts" '"pointId"\s*,\s*' 'pointId: null,' ([ref]$patchLog) | Out-Null

# 5) regex quebrada por newline em confirm/replicar/support (vira /confirm/i, etc)
ReplaceRegex "src\app\api\eco\points\confirm\route.ts"   '\/\s*\r?\n\s*confirm\s*\r?\n\s*\/i'   '/confirm/i'   ([ref]$patchLog) | Out-Null
ReplaceRegex "src\app\api\eco\points\replicar\route.ts"  '\/\s*\r?\n\s*replicar\s*\r?\n\s*\/i'  '/replicar/i'  ([ref]$patchLog) | Out-Null
ReplaceRegex "src\app\api\eco\points\support\route.ts"   '\/\s*\r?\n\s*support\s*\r?\n\s*\/i'   '/support/i'   ([ref]$patchLog) | Out-Null

# 6) receipt-card: route.ts -> route.tsx (JSX)
$rcTs  = "src\app\api\share\receipt-card\route.ts"
$rcTsx = "src\app\api\share\receipt-card\route.tsx"
if((Test-Path -LiteralPath $rcTs) -and !(Test-Path -LiteralPath $rcTsx)){
  BackupFile $rcTs "tools\_patch_backup" | Out-Null
  Move-Item -LiteralPath $rcTs -Destination $rcTsx -Force
  $patchLog += "[OK]   rename: receipt-card route.ts -> route.tsx`n"
}

# 7) pedidos/page.tsx: texto sem aspas
ReplaceRegex "src\app\pedidos\page.tsx" 'GET\s*\/api\/pickup-requests\s*falhou[^\r\n]*' '"GET /api/pickup-requests falhou"' ([ref]$patchLog) | Out-Null

# 8) recibo-client.tsx: bloco const url quebrado (caminho com [code] -> literal)
$reciboClient = "src\app\recibo\[code]\recibo-client.tsx"
$patUrl = 'const\s+url\s*=\s*[\s\S]*?\r?\n(\s*const\s+res\s*=\s*await\s+fetch\(\s*url)'
$repUrl = @(
  'const url =',
  '  "/api/receipts?code=" + encodeURIComponent(code) + (operatorToken ? "&token=" + encodeURIComponent(operatorToken) : "");',
  '$1'
) -join "`n"
ReplaceRegex $reciboClient $patUrl $repUrl ([ref]$patchLog) | Out-Null

# 9) /chamar/sucesso/page.tsx: reescreve minimo funcional
$chamarOk = "src\app\chamar\sucesso\page.tsx"
if(Test-Path -LiteralPath $chamarOk){ BackupFile $chamarOk "tools\_patch_backup" | Out-Null }
$chamarLines = @(
  'import Link from "next/link";',
  '',
  'export default function Page({ searchParams }: { searchParams?: Record<string, string | string[] | undefined> }) {',
  '  const codeRaw = searchParams?.code;',
  '  const code = Array.isArray(codeRaw) ? codeRaw[0] : codeRaw;',
  '  return (',
  '    <main className="mx-auto max-w-2xl p-6">',
  '      <h1 className="text-2xl font-bold">Pedido enviado</h1>',
  '      <p className="mt-2 text-sm opacity-80">Se precisar, voce pode acompanhar na lista de pedidos.</p>',
  '      {code ? (',
  '        <div className="mt-4 rounded border border-neutral-800 bg-neutral-950 p-3">',
  '          <div className="text-xs opacity-70">Codigo</div>',
  '          <div className="font-mono">{code}</div>',
  '        </div>',
  '      ) : null}',
  '      <div className="mt-6 flex gap-3">',
  '        <Link className="rounded bg-emerald-500 px-4 py-2 font-semibold text-black" href="/pedidos">Ver pedidos</Link>',
  '        <Link className="rounded border border-neutral-700 px-4 py-2" href="/eco">Voltar ao ECO</Link>',
  '      </div>',
  '    </main>',
  '  );',
  '}'
)
WriteLines $chamarOk $chamarLines
$patchLog += "[OK]   reescrito: $chamarOk`n"

# 10) /eco/mutiroes/[id]/page.tsx: reescreve minimo funcional
$mutPage = "src\app\eco\mutiroes\[id]\page.tsx"
if(Test-Path -LiteralPath $mutPage){ BackupFile $mutPage "tools\_patch_backup" | Out-Null }
$mutLines = @(
  'import Link from "next/link";',
  '',
  'export default function Page({ params }: { params: { id: string } }) {',
  '  const id = String(params?.id || "");',
  '  const hrefFinalize = "/eco/mutiroes/" + encodeURIComponent(id) + "/finalizar";',
  '  return (',
  '    <main className="mx-auto max-w-3xl p-6">',
  '      <div className="text-xs opacity-70">Mutirao</div>',
  '      <h1 className="text-2xl font-bold">{id || "Sem id"}</h1>',
  '      <div className="mt-6 flex gap-3">',
  '        <Link className="rounded bg-emerald-500 px-4 py-2 font-semibold text-black" href={hrefFinalize}>Finalizar</Link>',
  '        <Link className="rounded border border-neutral-700 px-4 py-2" href="/eco/mutiroes">Voltar</Link>',
  '      </div>',
  '    </main>',
  '  );',
  '}'
)
WriteLines $mutPage $mutLines
$patchLog += "[OK]   reescrito: $mutPage`n"

# VERIFY
$verify = @()
function RunCmd([string]$label,[scriptblock]$sb){
  $verify += ""
  $verify += ("### " + $label)
  try { $o = (& $sb 2>&1 | Out-String).TrimEnd(); $verify += "~~~"; $verify += $o; $verify += "~~~" }
  catch { $verify += ("(erro: " + $_.Exception.Message + ")") }
}
RunCmd "npm run lint" { npm run lint }
RunCmd "npm run build" { npm run build }

# REPORT
$r = @()
$r += ("# eco-step-149 — fix compile blockers — " + $stamp)
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
Write-Host "[NEXT] rode o auto-smoke:"
Write-Host "  pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport"