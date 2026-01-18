Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
function ReadText([string]$p){ return [System.IO.File]::ReadAllText($p) }
function WriteText([string]$p, [string]$t){ WriteUtf8NoBom $p $t }

function FindFirst([string]$root, [string]$pattern){
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } | Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

function DetectModelField([string[]]$lines, [string]$modelName, [string[]]$candidates){
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+$modelName\s*\{"){ $start = $i; break }
  }
  if($start -lt 0){ return $null }
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return $null }

  $found = @{}
  for($k=$start; $k -le $end; $k++){
    $line = $lines[$k].Trim()
    if($line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\b"){
      $fname = $Matches[1]
      $found[$fname] = $true
    }
  }
  foreach($c in $candidates){
    if($found.ContainsKey($c)){ return $c }
  }
  return $null
}

function GetBracketFolderInfo([string]$dirPath, [string]$fallback){
  if(!(Test-Path -LiteralPath $dirPath)){
    return @{ folder = $fallback; param = ($fallback.Trim('[',']')) }
  }
  $dirs = @(
    Get-ChildItem -LiteralPath $dirPath -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match '^\[.+\]$' }
  )
  if($dirs.Count -ge 1){
    $folder = $dirs[0].Name
    return @{ folder = $folder; param = ($folder.Trim('[',']')) }
  }
  return @{ folder = $fallback; param = ($fallback.Trim('[',']')) }
}

function ExtractTokenKeyFromReceiptLink([string]$p){
  if(!(Test-Path -LiteralPath $p)){ return $null }
  $t = ReadText $p
  $m = [regex]::Match($t, 'localStorage\.getItem\((["''])(?<k>[^"''\)]+)\1\)')
  if($m.Success){ return $m.Groups['k'].Value }
  return $null
}

$rep = NewReport "eco-step-23b-receipt-public-toggle-fix"
$log = @()
$log += "# ECO — STEP 23b — Recibo público/privado + botão publicar + link sem token quando público"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# Paths
$receiptLink = if(Test-Path "src/components/eco/ReceiptLink.tsx"){ "src/components/eco/ReceiptLink.tsx" } else { FindFirst "." "\\src\\components\\.*ReceiptLink\.tsx$" }
if(!$receiptLink){ throw "Não achei ReceiptLink.tsx" }

$sucesso = "src/app/chamar/sucesso/page.tsx"
if(!(Test-Path -LiteralPath $sucesso)){ throw "Não achei $sucesso" }

$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$tokenKey = ExtractTokenKeyFromReceiptLink $receiptLink
if(!$tokenKey){ $tokenKey = "eco_token" }

# Detect receipt fields
$receiptCodeField = "code"
$receiptPublicField = $null
if($schema -and (Test-Path -LiteralPath $schema)){
  $lines = Get-Content -LiteralPath $schema
  $receiptCodeField = (DetectModelField $lines "Receipt" @("code","shareCode","publicCode","slug","id"))
  if(!$receiptCodeField){ $receiptCodeField = "id" }
  $receiptPublicField = (DetectModelField $lines "Receipt" @("public","isPublic"))
}

# API route folder + param
$apiReceiptsDir = "src/app/api/receipts"
$info = GetBracketFolderInfo $apiReceiptsDir "[code]"
$dynFolder = $info.folder
$paramName = $info.param

$apiToggle = Join-Path $apiReceiptsDir (Join-Path $dynFolder "public/route.ts")

$log += "## DIAG"
$log += ("ReceiptLink: {0}" -f $receiptLink)
$log += ("Token key: {0}" -f $tokenKey)
$log += ("Schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("Receipt code field: {0}" -f $receiptCodeField)
$log += ("Receipt public field: {0}" -f ($receiptPublicField ? $receiptPublicField : "(nenhum)"))
$log += ("API dyn folder: {0} (param: {1})" -f $dynFolder, $paramName)
$log += ("API toggle path: {0}" -f $apiToggle)
$log += ""

$log += "## PATCH"

# (1) Publish button component
$publishComp = "src/components/eco/ReceiptPublishButton.tsx"
$log += ("Backup: {0}" -f (BackupFile $publishComp))

$pubField = $receiptPublicField
if(!$pubField){ $pubField = "public" } # fallback: mantém "public" (se não existir, vai dar erro e a gente ajusta)
$comp = @"
'use client';

import React from 'react';

function ecoReadToken(): string | null {
  try {
    const keys = ['__TOKEN_KEY__', 'eco_token', 'eco_operator_token', 'ECO_TOKEN', 'ECO_OPERATOR_TOKEN'];
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
  const code = receipt?.__CODE_FIELD__ as string | undefined;
  const initialPublic = !!receipt?.__PUBLIC_FIELD__;

  const [isPublic, setIsPublic] = React.useState<boolean>(initialPublic);
  const [busy, setBusy] = React.useState<boolean>(false);
  const [err, setErr] = React.useState<string | null>(null);

  React.useEffect(() => {
    setIsPublic(!!receipt?.__PUBLIC_FIELD__);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [receipt?.__PUBLIC_FIELD__, receipt?.__CODE_FIELD__]);

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
$comp = $comp.Replace("__TOKEN_KEY__", $tokenKey).Replace("__CODE_FIELD__", $receiptCodeField).Replace("__PUBLIC_FIELD__", $pubField)
WriteText $publishComp $comp
$log += "- OK: ReceiptPublishButton criado/atualizado."

# (2) API toggle
$log += ("Backup: {0}" -f (BackupFile $apiToggle))
EnsureDir (Split-Path -Parent $apiToggle)

$api = @"
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

export async function PATCH(req: Request, { params }: { params: { __PARAM__: string } }) {
  if (!ecoIsOperator(req)) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const code = params?.__PARAM__ ? String(params.__PARAM__) : '';
  if (!code) return NextResponse.json({ error: 'missing_code' }, { status: 400 });

  let desired: boolean | null = null;
  try {
    const body = await req.json();
    if (typeof body?.public === 'boolean') desired = body.public;
  } catch {
    desired = null;
  }

  const current = await prisma.receipt.findFirst({
    where: { __CODE_FIELD__: code },
    select: { id: true, __CODE_FIELD__: true, __PUBLIC_FIELD__: true },
  });

  if (!current) return NextResponse.json({ error: 'not_found' }, { status: 404 });

  const curVal = Boolean((current as any).__PUBLIC_FIELD__);
  const nextVal = (desired === null) ? !curVal : desired;

  await prisma.receipt.updateMany({
    where: { __CODE_FIELD__: code },
    data: { __PUBLIC_FIELD__: nextVal } as any,
  });

  return NextResponse.json({ code, public: nextVal });
}
"@
$api = $api.Replace("__PARAM__", $paramName).Replace("__CODE_FIELD__", $receiptCodeField).Replace("__PUBLIC_FIELD__", $pubField)
WriteText $apiToggle $api
$log += "- OK: API toggle criada/atualizada."

# (3) Patch ReceiptLink: permitir sem token quando publico
$log += ("Backup: {0}" -f (BackupFile $receiptLink))
$txtRL = ReadText $receiptLink

if($txtRL -match "ReceiptLinkFromItem"){
  # tenta substituir a checagem de token
  $pubCheck = "const __eco_public = !!(item as any)?.receipt?.$pubField;`n  if (!token && !__eco_public) return null;"
  if($txtRL -match "if\s*\(\s*!\s*token\s*\)\s*return\s*null\s*;"){
    $txtRL = [regex]::Replace($txtRL, "if\s*\(\s*!\s*token\s*\)\s*return\s*null\s*;", $pubCheck, 1)
    $log += "- OK: ReceiptLinkFromItem agora deixa link sem token quando recibo é público."
  } else {
    $log += "- WARN: Não achei `if (!token) return null;` em ReceiptLink.tsx (skip)."
  }
} else {
  $log += "- WARN: ReceiptLinkFromItem não encontrado (skip)."
}
WriteText $receiptLink $txtRL

# (4) Patch chamar/sucesso: inserir botão ao lado do link
$log += ("Backup: {0}" -f (BackupFile $sucesso))
$txtPg = ReadText $sucesso

if($txtPg -notmatch "ReceiptPublishButtonFromItem"){
  # inserir import
  if($txtPg -match "ReceiptLink"){
    $txtPg = [regex]::Replace(
      $txtPg,
      "(import\s+\{\s*ReceiptLinkFromItem\s*\}\s+from\s+['""][^'""]*ReceiptLink['""]\s*;)",
      "`$1`nimport { ReceiptPublishButtonFromItem } from '@/components/eco/ReceiptPublishButton';",
      1
    )
    if($txtPg -notmatch "ReceiptPublishButtonFromItem"){
      # fallback: após último import
      $mImp = [regex]::Matches($txtPg, "^\s*import\s+.*?;\s*$", "Multiline")
      if($mImp.Count -gt 0){
        $last = $mImp[$mImp.Count-1]
        $insAt = $last.Index + $last.Length
        $txtPg = $txtPg.Insert($insAt, "`nimport { ReceiptPublishButtonFromItem } from '@/components/eco/ReceiptPublishButton';")
      }
    }
  }

  # inserir componente perto do ReceiptLinkFromItem pegando mesma variável item={X}
  $m = [regex]::Match($txtPg, "<ReceiptLinkFromItem[^>]*item=\{(?<v>[A-Za-z_][A-Za-z0-9_]*)\}[^>]*/>")
  if($m.Success){
    $v = $m.Groups["v"].Value
    $inject = $m.Value + "`n" + "<ReceiptPublishButtonFromItem item={$v} />"
    $txtPg = $txtPg.Substring(0, $m.Index) + $inject + $txtPg.Substring($m.Index + $m.Length)
    $log += "- OK: botão publicar/privado inserido ao lado do link."
  } else {
    $log += "- WARN: não achei <ReceiptLinkFromItem item={X} /> para inserir botão."
  }
} else {
  $log += "- INFO: /chamar/sucesso já tinha ReceiptPublishButtonFromItem (skip)."
}
WriteText $sucesso $txtPg

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) /chamar/sucesso: com token aparece botão Publicar/Tornar privado"
$log += "4) Aba anônima: link Ver recibo só aparece se recibo estiver público"
$log += "5) API: PATCH /api/receipts/{param}/public (somente operador)"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 23b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /chamar/sucesso e /pedidos em aba normal vs anônima" -ForegroundColor Yellow