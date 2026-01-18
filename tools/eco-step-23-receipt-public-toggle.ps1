Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function EnsureDir([string]$p) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function WriteUtf8NoBom([string]$path, [string]$content) {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Sanitize([string]$s) {
  $x = $s -replace '[\\/:*?"<>|]', '_'
  return $x
}

function BackupFile([string]$filePath, [string]$stamp) {
  if (-not (Test-Path $filePath)) { return $null }
  EnsureDir 'tools/_patch_backup'
  $name = Sanitize($filePath)
  $dest = "tools/_patch_backup/$stamp-$name"
  Copy-Item -Force $filePath $dest
  return $dest
}

function ReadText([string]$p) { return [System.IO.File]::ReadAllText($p) }

function WriteText([string]$p, [string]$t) {
  EnsureDir ([System.IO.Path]::GetDirectoryName($p))
  WriteUtf8NoBom $p $t
}

function InsertAfterFirst([string]$text, [string]$needle, [string]$insert) {
  $i = $text.IndexOf($needle)
  if ($i -lt 0) { return $text }
  $j = $i + $needle.Length
  return $text.Substring(0, $j) + $insert + $text.Substring($j)
}

function ReplaceFirstAfter([string]$text, [int]$startIndex, [string]$from, [string]$to) {
  $i = $text.IndexOf($from, $startIndex)
  if ($i -lt 0) { return $text }
  return $text.Substring(0, $i) + $to + $text.Substring($i + $from.Length)
}

function FindFirstExistingPath([string[]]$candidates) {
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  return $null
}

function GetDynFolderName([string]$parentDir, [string]$defaultName) {
  if (-not (Test-Path $parentDir)) { return $defaultName }
  $dirs = Get-ChildItem -Path $parentDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\[.+\]$' }
  if ($dirs -and $dirs.Count -ge 1) { return $dirs[0].Name }
  return $defaultName
}

function ExtractTokenKeyFromReceiptLink([string]$receiptLinkPath) {
  if (-not (Test-Path $receiptLinkPath)) { return $null }
  $t = ReadText $receiptLinkPath
  $m = [regex]::Match($t, 'localStorage\.getItem\((["''])(?<k>[^"''\)]+)\1\)')
  if ($m.Success) { return $m.Groups['k'].Value }
  return $null
}

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
EnsureDir 'reports'
EnsureDir 'tools/_patch_backup'

$reportPath = "reports/$stamp-eco-step-23-receipt-public-toggle.md"
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# ECO — STEP 23 — Recibo público/privado (opt-in) + botão publicar + link sem token quando público")
$lines.Add("")
$lines.Add("Data: " + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
$lines.Add("PWD : " + (Get-Location).Path)
$lines.Add("")
$lines.Add("## DIAG")

$receiptLinkPath = FindFirstExistingPath @(
  'src/components/eco/ReceiptLink.tsx',
  'src/components/ReceiptLink.tsx'
)

if (-not $receiptLinkPath) {
  throw "Não achei ReceiptLink.tsx (esperei em src/components/eco/ReceiptLink.tsx)."
}

$tokenKey = ExtractTokenKeyFromReceiptLink $receiptLinkPath
if (-not $tokenKey) { $tokenKey = 'eco_token' }

$lines.Add("ReceiptLink: $receiptLinkPath")
$lines.Add("Token key (detectado): $tokenKey")

$chamarSucessoPath = FindFirstExistingPath @(
  'src/app/chamar/sucesso/page.tsx'
)
if (-not $chamarSucessoPath) {
  throw "Não achei src/app/chamar/sucesso/page.tsx"
}
$lines.Add("Página: $chamarSucessoPath")

$apiReceiptsDir = 'src/app/api/receipts'
$dynApiFolder = GetDynFolderName $apiReceiptsDir '[code]'
$apiTogglePath = Join-Path $apiReceiptsDir (Join-Path $dynApiFolder 'public/route.ts')
$lines.Add("API toggle: $apiTogglePath")

$lines.Add("")
$lines.Add("## PATCH")

# 1) Criar componente ReceiptPublishButton
$publishCompPath = 'src/components/eco/ReceiptPublishButton.tsx'
$backup1 = BackupFile $publishCompPath $stamp
if ($backup1) { $lines.Add("Backup (se existia): $backup1") }

$publishComp = @"
'use client';

import React from 'react';

function ecoReadToken(): string | null {
  try {
    const keys = ['${tokenKey}', 'eco_token', 'eco_operator_token', 'ECO_TOKEN', 'ECO_OPERATOR_TOKEN'];
    for (const k of keys) {
      const v = window.localStorage.getItem(k);
      if (v && v.trim()) return v.trim();
    }
    return null;
  } catch {
    return null;
  }
}

type AnyItem = any;

export function ReceiptPublishButtonFromItem({ item }: { item: AnyItem }) {
  const token = ecoReadToken();
  const receipt = (item as any)?.receipt;
  const code = receipt?.code as string | undefined;
  const initialPublic = !!receipt?.public;

  const [isPublic, setIsPublic] = React.useState<boolean>(initialPublic);
  const [busy, setBusy] = React.useState<boolean>(false);
  const [err, setErr] = React.useState<string | null>(null);

  React.useEffect(() => {
    setIsPublic(!!receipt?.public);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [receipt?.public, receipt?.code]);

  if (!code) return null;
  if (!token) return null;

  async function toggle() {
    setErr(null);
    setBusy(true);
    try {
      const res = await fetch('/api/receipts/' + encodeURIComponent(code) + '/public', {
        method: 'PATCH',
        headers: {
          'content-type': 'application/json',
          'x-eco-token': token,
        },
        body: JSON.stringify({ public: !isPublic }),
      });
      if (!res.ok) {
        const t = await res.text().catch(() => '');
        throw new Error('HTTP ' + res.status + (t ? ' — ' + t : ''));
      }
      const j = await res.json().catch(() => ({} as any));
      if (typeof (j as any)?.public === 'boolean') setIsPublic(!!(j as any).public);
    } catch (e: any) {
      setErr(e?.message ?? 'Falha ao atualizar');
    } finally {
      setBusy(false);
    }
  }

  return (
    <span className="inline-flex items-center gap-2">
      {isPublic ? (
        <span className="text-[11px] px-2 py-0.5 rounded border border-green-600/40 bg-green-600/10">
          Público
        </span>
      ) : (
        <span className="text-[11px] px-2 py-0.5 rounded border border-zinc-500/40 bg-zinc-500/10">
          Privado
        </span>
      )}

      <button
        type="button"
        onClick={toggle}
        disabled={busy}
        className="text-xs px-2 py-1 rounded border border-zinc-300 hover:bg-zinc-100 disabled:opacity-60"
        title="Alternar visibilidade do recibo"
      >
        {busy ? 'Salvando…' : (isPublic ? 'Tornar privado' : 'Publicar')}
      </button>

      {err ? <span className="text-xs text-red-600">{err}</span> : null}
    </span>
  );
}
"@
WriteText $publishCompPath $publishComp
$lines.Add("OK: criado/atualizado $publishCompPath")

# 2) Criar API PATCH /api/receipts/[code]/public
$backup2 = BackupFile $apiTogglePath $stamp
if ($backup2) { $lines.Add("Backup API (se existia): $backup2") }

EnsureDir ([System.IO.Path]::GetDirectoryName($apiTogglePath))

$apiToggle = @"
import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

function ecoGetToken(req: Request): string | null {
  const h = req.headers.get('x-eco-token') ?? req.headers.get('authorization') ?? '';
  if (h.startsWith('Bearer ')) return h.slice(7).trim();
  if (h && !h.includes(' ')) return h.trim();
  return null;
}

function ecoIsOperator(req: Request): boolean {
  const t = ecoGetToken(req);
  const op = process.env.ECO_OPERATOR_TOKEN ?? process.env.ECO_TOKEN ?? '';
  if (!op) return false;
  return !!t && t === op;
}

export async function PATCH(req: Request, { params }: { params: { code: string } }) {
  if (!ecoIsOperator(req)) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const code = params?.code ? String(params.code) : '';
  if (!code) return NextResponse.json({ error: 'missing_code' }, { status: 400 });

  let desired: boolean | null = null;
  try {
    const body = await req.json();
    if (typeof body?.public === 'boolean') desired = body.public;
  } catch {
    desired = null;
  }

  const current = await prisma.receipt.findFirst({
    where: { code },
    select: { id: true, code: true, public: true },
  });

  if (!current) return NextResponse.json({ error: 'not_found' }, { status: 404 });

  const nextVal = (desired === null) ? !current.public : desired;

  await prisma.receipt.updateMany({
    where: { code },
    data: { public: nextVal },
  });

  return NextResponse.json({ code, public: nextVal });
}
"@
WriteText $apiTogglePath $apiToggle
$lines.Add("OK: criado/atualizado $apiTogglePath")

# 3) Patch ReceiptLink: link aparece se token OU receipt.public = true
$backup3 = BackupFile $receiptLinkPath $stamp
$txtRL = ReadText $receiptLinkPath

$idxFn = $txtRL.IndexOf('ReceiptLinkFromItem')
if ($idxFn -ge 0) {
  # tenta trocar o "if (!token) return null;" dentro do ReceiptLinkFromItem
  $needle = 'if (!token) return null;'
  $insert = "const __eco_public = !!(item as any)?.receipt?.public;`n  if (!token && !__eco_public) return null;"
  $after = ReplaceFirstAfter $txtRL $idxFn $needle $insert
  if ($after -ne $txtRL) {
    $txtRL = $after
    $lines.Add("OK: ReceiptLinkFromItem agora permite link sem token quando receipt.public=true")
  } else {
    # fallback: procura variante com espaços
    $m = [regex]::Match($txtRL.Substring($idxFn), 'if\s*\(\s*!\s*token\s*\)\s*return\s*null\s*;')
    if ($m.Success) {
      $abs = $idxFn + $m.Index
      $txtRL = $txtRL.Substring(0, $abs) + "const __eco_public = !!(item as any)?.receipt?.public;`n  if (!token && !__eco_public) return null;" + $txtRL.Substring($abs + $m.Length)
      $lines.Add("OK: ReceiptLinkFromItem (fallback regex) atualizado para considerar receipt.public")
    } else {
      $lines.Add("WARN: não achei o 'if (!token) return null;' dentro do ReceiptLinkFromItem. Nenhuma mudança aplicada em ReceiptLink.tsx.")
    }
  }
} else {
  $lines.Add("WARN: ReceiptLinkFromItem não encontrado em ReceiptLink.tsx (não apliquei patch do link público).")
}

WriteText $receiptLinkPath $txtRL
if ($backup3) { $lines.Add("Backup ReceiptLink: $backup3") }

# 4) Patch chamar/sucesso: inserir ReceiptPublishButtonFromItem ao lado do link
$backup4 = BackupFile $chamarSucessoPath $stamp
$txtPage = ReadText $chamarSucessoPath

if ($txtPage -notmatch 'ReceiptPublishButtonFromItem') {
  # import
  if ($txtPage -match "from\s+['""]@/components/eco/ReceiptLink['""]") {
    $txtPage = InsertAfterFirst $txtPage "from '@/components/eco/ReceiptLink';" "`nimport { ReceiptPublishButtonFromItem } from '@/components/eco/ReceiptPublishButton';"
    $lines.Add("OK: import ReceiptPublishButtonFromItem inserido após ReceiptLink")
  } else {
    # fallback: injeta após último import
    $mImp = [regex]::Matches($txtPage, "import\s+.+?;")
    if ($mImp.Count -gt 0) {
      $last = $mImp[$mImp.Count - 1]
      $pos = $last.Index + $last.Length
      $txtPage = $txtPage.Substring(0, $pos) + "`nimport { ReceiptPublishButtonFromItem } from '@/components/eco/ReceiptPublishButton';" + $txtPage.Substring($pos)
      $lines.Add("OK: import ReceiptPublishButtonFromItem inserido após último import (fallback)")
    } else {
      $lines.Add("WARN: não achei imports para inserir ReceiptPublishButtonFromItem (pulei import).")
    }
  }

  # JSX: inserir ao lado do ReceiptLinkFromItem
  $mLink = [regex]::Match($txtPage, "<ReceiptLinkFromItem[^>]*\/>")
  if ($mLink.Success) {
    $snippet = $mLink.Value
    $inject = $snippet + "`n" + "<ReceiptPublishButtonFromItem item={item} />"
    $txtPage = $txtPage.Substring(0, $mLink.Index) + $inject + $txtPage.Substring($mLink.Index + $mLink.Length)
    $lines.Add("OK: botão Publicar/Privado inserido ao lado do 'Ver recibo' (mesmo item do map)")
  } else {
    $lines.Add("WARN: não achei <ReceiptLinkFromItem ... /> para inserir botão. (pulei JSX)")
  }
} else {
  $lines.Add("INFO: chamar/sucesso já tem ReceiptPublishButtonFromItem (skip)")
}

WriteText $chamarSucessoPath $txtPage
if ($backup4) { $lines.Add("Backup page: $backup4") }

$lines.Add("")
$lines.Add("## VERIFY")
$lines.Add("1) Reinicie o dev (CTRL+C): npm run dev")
$lines.Add("2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1")
$lines.Add("3) Teste /pedidos (chamar/sucesso): com token você vê botão Publicar/Privado; sem token, o link só aparece se o recibo estiver público.")
$lines.Add("4) API: PATCH /api/receipts/{code}/public (somente operador)")

WriteText $reportPath ($lines -join "`n")

Write-Host "✅ STEP 23 aplicado. Report -> $reportPath" -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev"
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
Write-Host "3) Abra /pedidos: publique um recibo e confira (aba anônima) que o link aparece quando Público."
