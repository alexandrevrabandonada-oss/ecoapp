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

function GetBlock([string[]]$lines, [string]$kind, [string]$name){
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match ("^\s*"+$kind+"\s+"+$name+"\s*\{")){ $start = $i; break }
  }
  if($start -lt 0){ return $null }
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return $null }
  return $lines[$start..$end]
}

function GetEnumNames([string[]]$lines){
  $names = @()
  for($i=0; $i -lt $lines.Count; $i++){
    $m = [regex]::Match($lines[$i], '^\s*enum\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{')
    if($m.Success){ $names += $m.Groups[1].Value }
  }
  return $names
}

function GetEnumFirstValue([string[]]$lines, [string]$enumName){
  $blk = GetBlock $lines "enum" $enumName
  if(!$blk){ return $null }
  for($i=0; $i -lt $blk.Count; $i++){
    $t = $blk[$i].Trim()
    if($t -match '^[A-Za-z_][A-Za-z0-9_]*$'){ return $t }
  }
  return $null
}

function DetectReceiptFields([string[]]$lines){
  $blk = GetBlock $lines "model" "Receipt"
  if(!$blk){
    return @{ code="code"; public="public"; required=@(); enums=@{} }
  }

  $enumNames = GetEnumNames $lines
  $enumSet = @{}
  foreach($e in $enumNames){ $enumSet[$e] = $true }

  $codeField = $null
  $publicField = $null

  # map enumName->firstValue
  $enumFirst = @{}
  foreach($e in $enumNames){
    $v = GetEnumFirstValue $lines $e
    if($v){ $enumFirst[$e] = $v }
  }

  $required = @()

  foreach($ln in $blk){
    $t = $ln.Trim()
    if(!$t){ continue }
    if($t.StartsWith("//")){ continue }
    if($t.StartsWith("@@")){ continue }
    if($t -match '^\}'){ continue }

    $m = [regex]::Match($t, '^([A-Za-z_][A-Za-z0-9_]*)\s+([A-Za-z_][A-Za-z0-9_]*)(\?)?\b(.*)$')
    if(!$m.Success){ continue }

    $fname = $m.Groups[1].Value
    $ftype = $m.Groups[2].Value
    $opt = $m.Groups[3].Success
    $rest = $m.Groups[4].Value

    # detect likely code/public names
    if(!$codeField -and ($fname -ieq "code" -or $fname -ieq "shareCode" -or $fname -ieq "publicCode")){ $codeField = $fname }
    if(!$publicField -and ($fname -ieq "public" -or $fname -ieq "isPublic")){ $publicField = $fname }

    # skip id / timestamps / relation-ish
    if($fname -ieq "id"){ continue }
    if($fname -ieq "createdAt"){ continue }
    if($fname -ieq "updatedAt"){ continue }

    $hasDefault = $false
    if($rest -match '@default\('){ $hasDefault = $true }
    if($rest -match '@id\b'){ $hasDefault = $true }
    if($rest -match '@updatedAt\b'){ $hasDefault = $true }

    # scalar types
    $isScalar = $false
    $scalarTypes = @("String","Int","Float","Boolean","DateTime","Json","Bytes","BigInt","Decimal")
    foreach($s in $scalarTypes){ if($ftype -eq $s){ $isScalar = $true; break } }

    $isEnum = $false
    if($enumSet.ContainsKey($ftype)){ $isEnum = $true }

    if(!$isScalar -and !$isEnum){
      # probably relation field -> ignore
      continue
    }

    if(!$opt -and !$hasDefault){
      $required += @{ name=$fname; type=$ftype; isEnum=$isEnum }
    }
  }

  if(!$codeField){ $codeField = "code" }
  if(!$publicField){ $publicField = "public" }

  return @{ code=$codeField; public=$publicField; required=$required; enums=$enumFirst }
}

function EnsureImportLine([string]$txt, [string]$needle, [string]$line){
  if($txt -match [regex]::Escape($needle)){ return $txt }
  $mImp = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
  $insAt = 0
  if($mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
  }
  return $txt.Insert($insAt, "`n" + $line)
}

$rep = NewReport "eco-step-23-issue-receipt-from-pedidos"
$log = @()
$log += "# ECO — STEP 23 — Emitir recibo a partir do /pedidos"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# == DIAG ==
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$receiptInfo = @{ code="code"; public="public"; required=@(); enums=@{} }
if($schema -and (Test-Path -LiteralPath $schema)){
  $lines = Get-Content -LiteralPath $schema
  $receiptInfo = DetectReceiptFields $lines
}

$receiptCodeField = $receiptInfo.code
$receiptPublicField = $receiptInfo.public

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("Receipt.code field: {0}" -f $receiptCodeField)
$log += ("Receipt.public field: {0}" -f $receiptPublicField)
$log += ("Receipt required fields (sem default): {0}" -f ($receiptInfo.required.Count))
if($receiptInfo.required.Count -gt 0){
  foreach($r in $receiptInfo.required){
    $log += ("- {0} : {1}" -f $r.name, $r.type)
  }
}
$log += ""

# == PATCH 1: API POST /api/pickup-requests/[id]/receipt ==
$apiDir = "src/app/api/pickup-requests/[id]/receipt"
$apiFile = Join-Path $apiDir "route.ts"
EnsureDir $apiDir

$log += "## PATCH — API"
$log += ("arquivo: {0}" -f $apiFile)
if(Test-Path -LiteralPath $apiFile){ $log += ("backup : {0}" -f (BackupFile $apiFile)) }

# montar payload TS do create (via nested create)
$createProps = @()

# required fields sem default -> preencher com placeholder seguro
foreach($r in $receiptInfo.required){
  $n = $r.name
  $t = $r.type
  $isEnum = $r.isEnum

  # não duplicar code/public se já vamos setar abaixo
  if($n -ieq $receiptCodeField){ continue }
  if($n -ieq $receiptPublicField){ continue }

  if($isEnum){
    $v = $null
    if($receiptInfo.enums.ContainsKey($t)){ $v = $receiptInfo.enums[$t] }
    if(!$v){ $v = "UNKNOWN" }
    $createProps += ("    " + $n + ": " + '"' + $v + '"' + " as any,")
    continue
  }

  switch($t){
    "String"   { $createProps += ("    " + $n + ": " + '"' + "MVP" + '"' + ","); break }
    "Int"      { $createProps += ("    " + $n + ": 0,"); break }
    "Float"    { $createProps += ("    " + $n + ": 0,"); break }
    "Boolean"  { $createProps += ("    " + $n + ": false,"); break }
    "DateTime" { $createProps += ("    " + $n + ": new Date(),"); break }
    "Json"     { $createProps += ("    " + $n + ": {} as any,"); break }
    default    { $createProps += ("    " + $n + ": null as any,"); break }
  }
}

# sempre setar code/public (se existirem mesmo)
$createPropsCode = ("    " + $receiptCodeField + ": ecoGenCode(),")
$createPropsPublic = ("    " + $receiptPublicField + ": false,")

$selectReceipt = @(
  ("        " + $receiptCodeField + ": true,"),
  ("        " + $receiptPublicField + ": true,")
)

$ts = @()
$ts += 'import { NextResponse } from "next/server";'
$ts += 'import { PrismaClient } from "@prisma/client";'
$ts += 'import crypto from "node:crypto";'
$ts += ''
$ts += 'export const runtime = "nodejs";'
$ts += ''
$ts += 'const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };'
$ts += 'const prisma = globalForPrisma.prisma ?? new PrismaClient();'
$ts += 'if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;'
$ts += ''
$ts += 'function ecoGetToken(req: Request): string | null {'
$ts += '  const h = req.headers.get("x-eco-token") ?? req.headers.get("authorization") ?? "";'
$ts += '  if (h.startsWith("Bearer ")) return h.slice(7).trim();'
$ts += '  if (h && !h.includes(" ")) return h.trim();'
$ts += '  return null;'
$ts += '}'
$ts += ''
$ts += 'function ecoIsOperator(req: Request): boolean {'
$ts += '  const t = ecoGetToken(req);'
$ts += '  if (!t) return false;'
$ts += '  const allow = (process.env.ECO_OPERATOR_TOKEN ?? process.env.ECO_TOKEN ?? "").trim();'
$ts += '  if (!allow) return false;'
$ts += '  return t === allow;'
$ts += '}'
$ts += ''
$ts += 'function ecoGenCode(): string {'
$ts += '  const raw = crypto.randomBytes(9).toString("base64url").replace(/[^a-zA-Z0-9]/g, "");'
$ts += '  return raw.slice(0, 10);'
$ts += '}'
$ts += ''
$ts += 'export async function POST(req: Request, ctx: { params: { id: string } }) {'
$ts += '  try {'
$ts += '    const id = String((ctx as any)?.params?.id ?? "");'
$ts += '    if (!id) return NextResponse.json({ ok: false, error: "missing_id" }, { status: 400 });'
$ts += ''
$ts += '    if (!ecoIsOperator(req)) {'
$ts += '      return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });'
$ts += '    }'
$ts += ''
$ts += '    const existing = await prisma.pickupRequest.findUnique({'
$ts += '      where: { id },'
$ts += '      select: {'
$ts += '        id: true,'
$ts += '        receipt: { select: {'
foreach($l in $selectReceipt){ $ts += $l }
$ts += '        } },'
$ts += '      },'
$ts += '    });'
$ts += ''
$ts += '    if (!existing) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });'
$ts += '    if (existing.receipt) {'
$ts += '      return NextResponse.json({ ok: true, receipt: existing.receipt }, { status: 200 });'
$ts += '    }'
$ts += ''
$ts += '    const updated = await prisma.pickupRequest.update({'
$ts += '      where: { id },'
$ts += '      data: {'
$ts += '        receipt: {'
$ts += '          create: {'
$ts += $createPropsCode
$ts += $createPropsPublic
foreach($p in $createProps){ $ts += $p }
$ts += '          },'
$ts += '        },'
$ts += '      },'
$ts += '      select: {'
$ts += '        id: true,'
$ts += '        receipt: { select: {'
foreach($l in $selectReceipt){ $ts += $l }
$ts += '        } },'
$ts += '      },'
$ts += '    });'
$ts += ''
$ts += '    return NextResponse.json({ ok: true, receipt: updated.receipt }, { status: 200 });'
$ts += '  } catch (e: any) {'
$ts += '    console.error("issue receipt error", e);'
$ts += '    return NextResponse.json({ ok: false, error: "server_error" }, { status: 500 });'
$ts += '  }'
$ts += '}'

WriteUtf8NoBom $apiFile ($ts -join "`n")
$log += "- OK: criado endpoint POST /api/pickup-requests/[id]/receipt."

# == PATCH 2: componente client do botão ==
$btnFile = "src/components/eco/IssueReceiptButton.tsx"
EnsureDir (Split-Path -Parent $btnFile)

$log += ""
$log += "## PATCH — UI (client component)"
$log += ("arquivo: {0}" -f $btnFile)
if(Test-Path -LiteralPath $btnFile){ $log += ("backup : {0}" -f (BackupFile $btnFile)) }

$btn = @()
$btn += '"use client";'
$btn += 'import React from "react";'
$btn += ''
$btn += 'function ecoReadToken(): string {'
$btn += '  try {'
$btn += '    return ('
$btn += '      localStorage.getItem("eco_token") ??'
$btn += '      localStorage.getItem("ECO_TOKEN") ??'
$btn += '      localStorage.getItem("token") ??'
$btn += '      ""'
$btn += '    ).trim();'
$btn += '  } catch {'
$btn += '    return "";'
$btn += '  }'
$btn += '}'
$btn += ''
$btn += 'export function IssueReceiptButton(props: { pickupId: string; label?: string; onIssued?: () => void }) {'
$btn += '  const [hasToken, setHasToken] = React.useState(false);'
$btn += '  const [busy, setBusy] = React.useState(false);'
$btn += ''
$btn += '  React.useEffect(() => {'
$btn += '    setHasToken(!!ecoReadToken());'
$btn += '  }, []);'
$btn += ''
$btn += '  if (!hasToken) return null;'
$btn += ''
$btn += '  const onClick = async () => {'
$btn += '    try {'
$btn += '      if (busy) return;'
$btn += '      setBusy(true);'
$btn += '      const t = ecoReadToken();'
$btn += '      const headers: Record<string, string> = { "content-type": "application/json" };'
$btn += '      if (t) headers["x-eco-token"] = t;'
$btn += ''
$btn += '      const r = await fetch(`/api/pickup-requests/${props.pickupId}/receipt`, { method: "POST", headers });'
$btn += '      if (!r.ok) {'
$btn += '        const txt = await r.text().catch(() => "");'
$btn += '        console.error("emitir recibo falhou", r.status, txt);'
$btn += '        alert(`Falhou ao emitir recibo (${r.status}). Veja o console.`);'
$btn += '        return;'
$btn += '      }'
$btn += ''
$btn += '      if (props.onIssued) props.onIssued();'
$btn += '      else window.location.reload();'
$btn += '    } catch (e) {'
$btn += '      console.error(e);'
$btn += '      alert("Erro ao emitir recibo. Veja o console.");'
$btn += '    } finally {'
$btn += '      setBusy(false);'
$btn += '    }'
$btn += '  };'
$btn += ''
$btn += '  return ('
$btn += '    <button'
$btn += '      type="button"'
$btn += '      onClick={onClick}'
$btn += '      disabled={busy}'
$btn += '      className="text-sm underline disabled:opacity-50"'
$btn += '      title="Emite e cola um Recibo ECO nesse pedido"'
$btn += '    >'
$btn += '      {busy ? "Emitindo..." : props.label ?? "Emitir recibo"}'
$btn += '    </button>'
$btn += '  );'
$btn += '}'
$btn += ''
$btn += 'export function IssueReceiptButtonFromItem(props: { item: any }) {'
$btn += '  const item: any = props.item;'
$btn += '  const id = String(item?.id ?? "");'
$btn += '  const code = item?.receipt?.code;'
$btn += '  if (!id) return null;'
$btn += '  if (code) return null;'
$btn += '  return <IssueReceiptButton pickupId={id} />;'
$btn += '}'

WriteUtf8NoBom $btnFile ($btn -join "`n")
$log += "- OK: criado IssueReceiptButton.tsx (client) com token + POST endpoint."

# == PATCH 3: inserir no /pedidos (page chamar/sucesso) ==
$page = "src/app/chamar/sucesso/page.tsx"
if(!(Test-Path -LiteralPath $page)){
  $page = FindFirst "." "\\src\\app\\chamar\\sucesso\\page\.tsx$"
}
$log += ""
$log += "## PATCH — Página (/pedidos)"
$log += ("arquivo: {0}" -f ($page ? $page : "(não achei)"))

if($page -and (Test-Path -LiteralPath $page)){
  $txt = Get-Content -LiteralPath $page -Raw
  $log += ("backup : {0}" -f (BackupFile $page))

  if($txt -notmatch "IssueReceiptButtonFromItem"){
    # import
    if($txt -match "ReceiptLinkFromItem"){
      $txt = EnsureImportLine $txt "IssueReceiptButtonFromItem" 'import { IssueReceiptButtonFromItem } from "@/components/eco/IssueReceiptButton";'
    } else {
      $txt = EnsureImportLine $txt "IssueReceiptButtonFromItem" 'import { IssueReceiptButtonFromItem } from "@/components/eco/IssueReceiptButton";'
    }

    # inserir uso perto do ReceiptLinkFromItem
    $markerStart = "// ECO_STEP23_ISSUE_RECEIPT_BTN_START"
    $markerEnd   = "// ECO_STEP23_ISSUE_RECEIPT_BTN_END"
    if($txt -notmatch [regex]::Escape($markerStart)){
      $needle = "ReceiptLinkFromItem"
      $idx = $txt.IndexOf($needle)
      if($idx -ge 0){
        # achar início da linha que contém o JSX do ReceiptLinkFromItem
        $lineStart = $txt.LastIndexOf("`n", $idx)
        if($lineStart -lt 0){ $lineStart = 0 } else { $lineStart = $lineStart + 1 }
        $insert = @()
        $insert += $markerStart
        $insert += "<IssueReceiptButtonFromItem item={item} />"
        $insert += $markerEnd
        $txt = $txt.Insert($lineStart, ($insert -join "`n") + "`n")
        $log += "- OK: inseri <IssueReceiptButtonFromItem item={item} /> antes do ReceiptLinkFromItem."
      } else {
        $log += "- WARN: não achei ReceiptLinkFromItem para ancorar; não injetei botão."
      }
    } else {
      $log += "- INFO: marcador do STEP 23 já existia; não reinjetei botão."
    }

    WriteUtf8NoBom $page $txt
  } else {
    $log += "- INFO: página já tem IssueReceiptButtonFromItem; skip."
  }
} else {
  $log += "- WARN: page.tsx não encontrada; botão não foi injetado."
}

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /pedidos (ou /chamar/sucesso): em pedido SEM recibo, deve aparecer 'Emitir recibo' (apenas com token)."
$log += "4) Clique 'Emitir recibo' -> página recarrega e aparece 'Ver recibo'."
$log += "5) Link abre /recibos/[code] normalmente."
$log += ""
$log += "## REGISTRO"
$log += "- Endpoints adicionados:"
$log += "  - POST /api/pickup-requests/[id]/receipt"
$log += "- UI adicionada:"
$log += "  - src/components/eco/IssueReceiptButton.tsx"
$log += "  - botão injetado em src/app/chamar/sucesso/page.tsx (perto do ReceiptLink)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 23 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /pedidos: emitir recibo (com token) e ver sumir (aba anônima)" -ForegroundColor Yellow