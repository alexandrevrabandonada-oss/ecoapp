$ErrorActionPreference = "Stop"

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
function FindFirst([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}
function FindLatestBackupFor([string]$hint){
  $bk = "tools/_patch_backup"
  if(!(Test-Path -LiteralPath $bk)){ return $null }
  $cands = Get-ChildItem -LiteralPath $bk -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*$hint*" } |
    Sort-Object Name -Descending
  if($cands.Count -gt 0){ return $cands[0].FullName }
  return $null
}

$rep = NewReport "eco-step-21d-recover-route-and-receiptlink-client-token"
$log = @()
$log += "# ECO — STEP 21d — Recover /api/pickup-requests + ReceiptLink client com token"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# (A) RECOVER route.ts a partir do backup mais recente
$route = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $route)){
  $route = FindFirst "." "\\src\\app\\api\\pickup-requests\\route\.ts$"
}
if(!(Test-Path -LiteralPath $route)){
  $log += "## DIAG"
  $log += "ERRO: não achei src/app/api/pickup-requests/route.ts"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei route.ts de pickup-requests"
}

$log += "## DIAG"
$log += ("route: {0}" -f $route)

$backupHint1 = "src_app_api_pickup-requests_route.ts"
$backupHint2 = "pickup-requests_route.ts"
$backup = FindLatestBackupFor $backupHint1
if(!$backup){ $backup = FindLatestBackupFor $backupHint2 }

$log += ("backup escolhido: {0}" -f ($backup ? $backup : "(nenhum encontrado)"))

if(!$backup){
  $log += ""
  $log += "⚠️ Não encontrei backup em tools/_patch_backup para pickup-requests/route.ts."
  $log += "Sugestão: confira se tools/_patch_backup existe e tem backups do arquivo."
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Sem backup para recuperar route.ts"
}

$log += ""
$log += "## PATCH — route.ts"
$log += ("Backup do estado atual: {0}" -f (BackupFile $route))
Copy-Item -Force -LiteralPath $backup -Destination $route
$log += ("OK: route.ts restaurado a partir de: {0}" -f $backup)

# (B) Criar componente client que só mostra link se houver token no localStorage
$comp = "src/components/eco/ReceiptLink.tsx"
EnsureDir (Split-Path -Parent $comp)

$compContent = @"
'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';

function getTokenFromStorage(): string {
  try {
    const t =
      (window.localStorage && (localStorage.getItem('eco_operator_token') || localStorage.getItem('eco_token'))) ||
      (window.sessionStorage && (sessionStorage.getItem('eco_operator_token') || sessionStorage.getItem('eco_token'))) ||
      '';
    return (t || '').trim();
  } catch {
    return '';
  }
}

function receiptCodeFromAny(item: any): string | null {
  if (!item) return null;
  const r = (item as any).receipt;
  const code =
    (r && (r.code || r.shareCode || r.publicCode || r.slug || r.id)) ||
    (item as any).receiptCode ||
    (item as any).receiptId ||
    null;
  if (!code) return null;
  return String(code);
}

export function ReceiptLink({ code }: { code: string }) {
  const [token, setToken] = useState<string>('');
  useEffect(() => {
    setToken(getTokenFromStorage());
  }, []);

  const href = useMemo(() => {
    const c = encodeURIComponent(code);
    const t = encodeURIComponent(token);
    return token ? '/recibo/' + c + '?token=' + t : '';
  }, [code, token]);

  if (!code) return null;
  if (!token) return null;

  return (
    <Link href={href} className="underline text-sm">
      Ver recibo
    </Link>
  );
}

export function ReceiptLinkFromItem({ item }: { item: any }) {
  const code = receiptCodeFromAny(item);
  if (!code) return null;
  return <ReceiptLink code={code} />;
}
"@

if(!(Test-Path -LiteralPath $comp)){
  WriteUtf8NoBom $comp $compContent
  $log += ""
  $log += "## PATCH — componente"
  $log += ("OK: criado {0}" -f $comp)
} else {
  $log += ""
  $log += "## PATCH — componente"
  $log += ("INFO: {0} já existe (não sobrescrevi)" -f $comp)
}

# (C) Patch na página onde aparece "Ver recibo" (STEP 19 apontou src/app/chamar/sucesso/page.tsx)
$page = "src/app/chamar/sucesso/page.tsx"
if(!(Test-Path -LiteralPath $page)){
  $page = FindFirst "." "\\src\\app\\chamar\\sucesso\\page\.tsx$"
}
if(!(Test-Path -LiteralPath $page)){
  $log += ""
  $log += "## PATCH — página"
  $log += "WARN: não achei src/app/chamar/sucesso/page.tsx (skip UI patch)."
} else {
  $txt = Get-Content -LiteralPath $page -Raw
  $log += ""
  $log += "## PATCH — página"
  $log += ("arquivo: {0}" -f $page)
  $log += ("backup : {0}" -f (BackupFile $page))

  # tenta detectar var do map (fallback: item)
  $varName = "item"
  $m = [regex]::Match($txt, "\.map\(\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)")
  if($m.Success){ $varName = $m.Groups[1].Value }

  # import do componente
  if($txt -notmatch "ReceiptLinkFromItem"){
    $importLine = "import { ReceiptLinkFromItem } from '../../../components/eco/ReceiptLink';"
    $mImp = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
    if($mImp.Count -gt 0){
      $last = $mImp[$mImp.Count-1]
      $insAt = $last.Index + $last.Length
      $txt = $txt.Insert($insAt, "`n" + $importLine)
      $log += "- OK: import ReceiptLinkFromItem inserido."
    } else {
      $txt = $importLine + "`n" + $txt
      $log += "- OK: import ReceiptLinkFromItem inserido no topo."
    }
  } else {
    $log += "- INFO: import/uso ReceiptLinkFromItem já existe (skip)."
  }

  # troca qualquer <Link ...>Ver recibo</Link> por <ReceiptLinkFromItem item={VAR} />
  $before = $txt
  $replacement = "<ReceiptLinkFromItem item={$varName} />"
  $txt = [regex]::Replace($txt, '(?s)<Link\b[^>]*>\s*Ver\s+recibo\s*</Link>', $replacement)

  if($txt -ne $before){
    $log += ("- OK: 'Ver recibo' agora só aparece com token (ReceiptLinkFromItem) | map var: {0}" -f $varName)
  } else {
    $log += "- WARN: não encontrei o bloco <Link>Ver recibo</Link> para substituir. (Nada mudado aqui.)"
  }

  WriteUtf8NoBom $page $txt
}

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) /api/pickup-requests deve voltar 200"
$log += "4) Página do STEP 19: 'Ver recibo' só aparece se houver token no localStorage (aba anônima deve sumir)"
$log += ""
WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 21d aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste: aba normal vs aba anônima (token no localStorage)" -ForegroundColor Yellow