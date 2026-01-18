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

$rep = NewReport "eco-step-26-public-receipt-sharebar-copy-wa"
$log = @()
$log += "# ECO — STEP 26 — Share Bar no recibo público (/r/[code])"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# (A) Criar componente client: ReceiptShareBar
$shareComp = "src/components/eco/ReceiptShareBar.tsx"
if(!(Test-Path -LiteralPath (Split-Path -Parent $shareComp))){
  EnsureDir (Split-Path -Parent $shareComp)
}
$bkA = BackupFile $shareComp

$shareTsx = @"
'use client';

import { useMemo } from 'react';

async function ecoCopy(text: string) {
  try {
    await navigator.clipboard.writeText(text);
    alert('Link copiado!');
  } catch {
    prompt('Copie o link:', text);
  }
}

export default function ReceiptShareBar(props: { code: string }) {
  const code = (props?.code ?? '').trim();

  const url = useMemo(() => {
    if (typeof window === 'undefined') return '';
    const origin = window.location?.origin ?? '';
    return origin + '/r/' + code;
  }, [code]);

  if (!code) return null;

  const onCopy = async () => {
    if (!url) return;
    await ecoCopy(url);
  };

  const onWhatsApp = () => {
    if (!url) return;
    const text = 'Recibo ECO: ' + url;
    const wa = 'https://wa.me/?text=' + encodeURIComponent(text);
    window.open(wa, '_blank', 'noopener,noreferrer');
  };

  return (
    <div className="my-4 flex flex-wrap items-center gap-3">
      <button type="button" onClick={onCopy} className="underline">
        Copiar link
      </button>
      <button type="button" onClick={onWhatsApp} className="underline">
        WhatsApp
      </button>
    </div>
  );
}
"@

WriteUtf8NoBom $shareComp $shareTsx

# (B) Injetar no page do recibo público: src/app/r/[code]/page.tsx
$page = "src/app/r/[code]/page.tsx"
if(!(Test-Path -LiteralPath $page)){
  $page = FindFirst "." "\\src\\app\\r\\\[code\]\\page\.tsx$"
}
if(!(Test-Path -LiteralPath $page)){
  $log += "ERRO: não achei src/app/r/[code]/page.tsx"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei a página do recibo público (/r/[code])."
}

$txt = Get-Content -LiteralPath $page -Raw
$bkB = BackupFile $page

$log += "## DIAG"
$log += ("ShareComp: {0}" -f $shareComp)
$log += ("Backup  A: {0}" -f ($bkA ? $bkA : "(novo)"))
$log += ("PublicPage: {0}" -f $page)
$log += ("Backup  B: {0}" -f $bkB)
$log += ""

$log += "## PATCH"

# Import (usar caminho relativo seguro: ../../../components/eco/ReceiptShareBar)
$importLine = "import ReceiptShareBar from '../../../components/eco/ReceiptShareBar';"

if($txt -match "ReceiptShareBar"){
  $log += "- INFO: page já contém ReceiptShareBar (skip import/insert)."
} else {
  # inserir import após o último import
  $mImp = @([regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline'))
  if($mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
    $txt = $txt.Insert($insAt, "`n$importLine")
    $log += "- OK: import inserido após último import."
  } else {
    $txt = $importLine + "`n" + $txt
    $log += "- OK: import inserido no topo."
  }

  # inserir componente dentro do JSX retornado
  $mRet = [regex]::Match($txt, 'return\s*\(\s*', 'IgnoreCase')
  if(!$mRet.Success){
    $log += "- WARN: não achei return(...). Não inseri ShareBar no JSX."
  } else {
    $pos = $mRet.Index + $mRet.Length

    # pular whitespace
    while($pos -lt $txt.Length -and [char]::IsWhiteSpace($txt[$pos])){ $pos++ }

    if($pos -ge $txt.Length -or $txt[$pos] -ne '<'){
      $log += "- WARN: return( não inicia com JSX. Não inseri ShareBar."
    } else {
      # fragment <> ?
      if($pos + 1 -lt $txt.Length -and $txt[$pos+1] -eq '>'){
        $posInsert = $pos + 2
        $ins = "`n      <ReceiptShareBar code={String((params as any)?.code ?? (params as any)?.id ?? '')} />`n"
        $txt = $txt.Insert($posInsert, $ins)
        $log += "- OK: ShareBar inserido após fragment <>."
      } else {
        $tagEnd = $txt.IndexOf('>', $pos)
        if($tagEnd -gt 0){
          $posInsert = $tagEnd + 1
          $ins = "`n      <ReceiptShareBar code={String((params as any)?.code ?? (params as any)?.id ?? '')} />`n"
          $txt = $txt.Insert($posInsert, $ins)
          $log += "- OK: ShareBar inserido após o primeiro tag do JSX."
        } else {
          $log += "- WARN: não achei fim do primeiro tag ('>'). Não inseri ShareBar."
        }
      }
    }
  }
}

WriteUtf8NoBom $page $txt
$log += "- OK: page salva."

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra um recibo público em /r/[code] e teste: Copiar link + WhatsApp"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 26 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code]: Copiar link + WhatsApp" -ForegroundColor Yellow