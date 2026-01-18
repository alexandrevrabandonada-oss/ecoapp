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

$rep = NewReport "eco-step-25-receiptlink-public-aware-and-copylink"
$log = @()
$log += "# ECO — STEP 25 — ReceiptLink: público sem token + copiar link"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# localizar componente
$comp = "src/components/eco/ReceiptLink.tsx"
if(!(Test-Path -LiteralPath $comp)){
  $comp = FindFirst "." "\\src\\components\\eco\\ReceiptLink\.tsx$"
}
if(!(Test-Path -LiteralPath $comp)){
  # cria do zero no path padrão
  $comp = "src/components/eco/ReceiptLink.tsx"
  EnsureDir (Split-Path -Parent $comp)
}

$log += "## DIAG"
$log += ("ReceiptLink: {0}" -f $comp)
$log += ""

$log += "## PATCH"
$bk = BackupFile $comp
if($bk){ $log += ("Backup: {0}" -f $bk) } else { $log += "Backup: (arquivo novo)" }

# reescrever componente (é nosso arquivo — mais seguro do que tentar regex em cima de estados quebrados)
$tsx = @"
'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';

type AnyItem = any;

function ecoReceiptFromItem(item: AnyItem): any | null {
  return (item?.receipt ?? item?.Receipt ?? item?.recibo ?? null) as any;
}

function ecoReceiptCodeFromItem(item: AnyItem): string | null {
  const r = ecoReceiptFromItem(item);
  const code =
    r?.code ??
    r?.shareCode ??
    r?.publicCode ??
    r?.slug ??
    r?.id;
  return (typeof code === 'string' && code.trim().length > 0) ? code.trim() : null;
}

function ecoReceiptIsPublicFromItem(item: AnyItem): boolean {
  const r = ecoReceiptFromItem(item);
  return Boolean(r?.public ?? r?.isPublic);
}

function ecoTokenFromLocalStorage(): string | null {
  try {
    const keys = ['eco_token','ECO_TOKEN','ecoToken','token'];
    for (const k of keys) {
      const v = localStorage.getItem(k);
      if (v && v.trim()) return v.trim();
    }
    return null;
  } catch {
    return null;
  }
}

async function ecoCopyText(text: string) {
  try {
    await navigator.clipboard.writeText(text);
    alert('Link copiado!');
  } catch {
    // fallback
    prompt('Copie o link:', text);
  }
}

export default function ReceiptLinkFromItem(props: { item: AnyItem }) {
  const item = props?.item;

  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    setToken(ecoTokenFromLocalStorage());
  }, []);

  const code = useMemo(() => ecoReceiptCodeFromItem(item), [item]);
  const isPublic = useMemo(() => ecoReceiptIsPublicFromItem(item), [item]);

  if (!code) return null;

  // regra: privado exige token; público não.
  if (!isPublic && !token) return null;

  const href = isPublic ? ('/r/' + code) : ('/recibos/' + code);

  const onCopy = async () => {
    const origin = (typeof window !== 'undefined' && window.location && window.location.origin) ? window.location.origin : '';
    const url = origin + '/r/' + code;
    await ecoCopyText(url);
  };

  return (
    <span className="inline-flex items-center gap-3">
      <Link href={href} className="underline">
        Ver recibo
      </Link>

      {isPublic ? (
        <button type="button" onClick={onCopy} className="underline">
          Copiar link
        </button>
      ) : null}
    </span>
  );
}
"@

WriteUtf8NoBom $comp $tsx
$log += "- OK: ReceiptLink.tsx reescrito com suporte a recibo público (/r/[code]) + copiar link."

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Teste /pedidos:"
$log += "   - aba anônima (sem token): 'Ver recibo' só aparece se receipt.public=true"
$log += "   - aba normal (com token): 'Ver recibo' aparece mesmo se privado"
$log += "   - se público: aparece 'Copiar link'"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 25 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /pedidos (aba normal vs anônima): público libera /r/[code]" -ForegroundColor Yellow