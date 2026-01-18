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
function RemoveBlockByMarkers([string]$txt, [string]$startMarker, [string]$endMarker){
  $pat = "(?s)\r?\n?\s*" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker) + "\s*\r?\n?"
  return [regex]::Replace($txt, $pat, "")
}
function InsertAfterLastImport([string]$txt, [string]$insert){
  $m = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
  if($m.Count -gt 0){
    $last = $m[$m.Count-1]
    $at = $last.Index + $last.Length
    return $txt.Insert($at, "`n`n" + $insert + "`n")
  }
  $idxUC = $txt.IndexOf("'use client'")
  if($idxUC -ge 0){
    $idxNL = $txt.IndexOf("`n", $idxUC)
    if($idxNL -ge 0){
      return $txt.Insert($idxNL + 1, "`n" + $insert + "`n")
    }
  }
  return ($insert + "`n" + $txt)
}
function InsertAfterMarker([string]$txt, [string]$marker, [string]$insert){
  $idx = $txt.IndexOf($marker)
  if($idx -lt 0){ return @{ ok=$false; txt=$txt } }
  $idxNL = $txt.IndexOf("`n", $idx)
  if($idxNL -lt 0){ return @{ ok=$false; txt=$txt } }
  $out = $txt.Insert($idxNL + 1, $insert)
  return @{ ok=$true; txt=$out }
}
function EnsureReactHooks([string]$txt, [string[]]$hooks){
  $reNamed = [regex]::new('^\s*import\s*\{\s*([^\}]+)\s*\}\s*from\s*["'']react["''];\s*$', 'Multiline')
  $m = $reNamed.Match($txt)
  if($m.Success){
    $list = $m.Groups[1].Value.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    $set = New-Object System.Collections.Generic.HashSet[string]
    foreach($it in $list){ [void]$set.Add($it) }
    foreach($h in $hooks){ if(-not $set.Contains($h)){ [void]$set.Add($h) } }
    $newList = ($set | Sort-Object) -join ", "
    $newLine = 'import { ' + $newList + ' } from "react";'
    return [regex]::Replace($txt, [regex]::Escape($m.Value), $newLine + "`n", "Multiline")
  }

  $reDefault = [regex]::new('^\s*import\s+React\s+from\s+["'']react["''];\s*$', 'Multiline')
  $m2 = $reDefault.Match($txt)
  if($m2.Success){
    $line2 = 'import { ' + (($hooks | Sort-Object) -join ", ") + ' } from "react";'
    $insert = $m2.Value.TrimEnd() + "`n" + $line2 + "`n"
    return [regex]::Replace($txt, [regex]::Escape($m2.Value), $insert, "Multiline")
  }

  # no react import found -> add one
  $line3 = 'import { ' + (($hooks | Sort-Object) -join ", ") + ' } from "react";'
  return (InsertAfterLastImport $txt $line3)
}

$rep = NewReport "eco-step-31-receipt-sharepack-toast"
$log = @()
$log += "# ECO — STEP 31 — ReceiptShareBar: toast 'Copiado!' + wrappers async"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$shareComp = "src/components/eco/ReceiptShareBar.tsx"
if(!(Test-Path -LiteralPath $shareComp)){
  $shareComp = FindFirst "." "\\src\\components\\eco\\ReceiptShareBar\.tsx$"
}
if(!(Test-Path -LiteralPath $shareComp)){
  $log += "## ERRO"
  $log += "Não achei src/components/eco/ReceiptShareBar.tsx"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei ReceiptShareBar.tsx"
}

$bk = BackupFile $shareComp
$txt = Get-Content -LiteralPath $shareComp -Raw

# detectar nome do prop/variável do código (default: code)
$codeVar = "code"
$m = [regex]::Match($txt, "ReceiptShareBar\s*\(\s*\{\s*([A-Za-z_][A-Za-z0-9_]*)", "IgnoreCase")
if($m.Success){
  $codeVar = $m.Groups[1].Value
}

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $shareComp)
$log += ("Backup : {0}" -f $bk)
$log += ("codeVar: {0}" -f $codeVar)
$log += ""

$log += "## PATCH"

# idempotência
$before = $txt
$txt = RemoveBlockByMarkers $txt "// ECO_STEP31_TOAST_STATE_START" "// ECO_STEP31_TOAST_STATE_END"
if($txt -ne $before){ $log += "- OK: removi bloco antigo STEP 31 (state/wrappers), se existia." }

# garantir hooks do React
$txt2 = EnsureReactHooks $txt @("useEffect","useState")
if($txt2 -ne $txt){
  $txt = $txt2
  $log += "- OK: garanti import de useState/useEffect."
} else {
  $log += "- INFO: imports de hooks já OK."
}

# inserir state + wrappers (ancora: dentro do componente logo após o começo da função)
# tentamos ancorar no "export default function ReceiptShareBar" ou "function ReceiptShareBar"
$toastBlock = @"
// ECO_STEP31_TOAST_STATE_START
  const [ecoToastMsg, setEcoToastMsg] = useState<string | null>(null);

  useEffect(() => {
    if (!ecoToastMsg) return;
    const t = setTimeout(() => setEcoToastMsg(null), 1200);
    return () => clearTimeout(t);
  }, [ecoToastMsg]);

  const ecoToast = (msg: string) => {
    setEcoToastMsg(msg);
  };

  const eco31_copyShort = async () => {
    await eco30_copyCaptionShort($codeVar);
    ecoToast("Legenda copiada!");
  };
  const eco31_copyLong = async () => {
    await eco30_copyCaptionLong($codeVar);
    ecoToast("Legenda longa copiada!");
  };
  const eco31_copyZap = async () => {
    await eco30_copyZap($codeVar);
    ecoToast("Mensagem do WhatsApp copiada!");
  };
  const eco31_shareText = async () => {
    await eco30_shareText($codeVar);
    ecoToast("Pronto!");
  };
// ECO_STEP31_TOAST_STATE_END
"@

$anchored = $false

# 1) padrão: export default function ReceiptShareBar(...) {
$re1 = [regex]::new("export\s+default\s+function\s+ReceiptShareBar\s*\([^\)]*\)\s*\{", "Multiline")
$m1 = $re1.Match($txt)
if($m1.Success){
  $insertAt = $m1.Index + $m1.Length
  $txt = $txt.Insert($insertAt, "`n" + $toastBlock + "`n")
  $anchored = $true
  $log += "- OK: inseri state/wrappers dentro do componente (export default function ReceiptShareBar)."
}

# 2) fallback: function ReceiptShareBar(...) {
if(-not $anchored){
  $re2 = [regex]::new("function\s+ReceiptShareBar\s*\([^\)]*\)\s*\{", "Multiline")
  $m2 = $re2.Match($txt)
  if($m2.Success){
    $insertAt = $m2.Index + $m2.Length
    $txt = $txt.Insert($insertAt, "`n" + $toastBlock + "`n")
    $anchored = $true
    $log += "- OK: inseri state/wrappers dentro do componente (function ReceiptShareBar)."
  }
}

if(-not $anchored){
  $log += "- WARN: não consegui ancorar dentro do componente ReceiptShareBar automaticamente. (state/wrappers não inseridos)"
}

# atualizar botões do STEP 30 pra usar wrappers do STEP 31
if($txt -match "ECO_STEP30_CAPTIONS_BUTTONS_START"){
  $txt = $txt.Replace("onClick={() => eco30_copyCaptionShort($codeVar)}","onClick={eco31_copyShort}")
  $txt = $txt.Replace("onClick={() => eco30_copyCaptionLong($codeVar)}","onClick={eco31_copyLong}")
  $txt = $txt.Replace("onClick={() => eco30_copyZap($codeVar)}","onClick={eco31_copyZap}")
  $txt = $txt.Replace("onClick={() => eco30_shareText($codeVar)}","onClick={eco31_shareText}")
  $log += "- OK: botões STEP 30 agora chamam wrappers do STEP 31."
} else {
  $log += "- WARN: não achei bloco de botões do STEP 30; não alterei onClick."
}

# inserir toast JSX logo após os botões do STEP 30
$toastJsx = @"
      {ecoToastMsg ? (
        <span className="text-xs opacity-80">{"{ecoToastMsg}"}</span>
      ) : null}
"@

$ins = InsertAfterMarker $txt "{/* ECO_STEP30_CAPTIONS_BUTTONS_END */}" ("`n" + $toastJsx)
if($ins.ok){
  $txt = $ins.txt
  $log += "- OK: toast JSX inserido após botões do STEP 30."
} else {
  $log += "- WARN: não achei âncora ECO_STEP30_CAPTIONS_BUTTONS_END pra inserir o toast JSX."
}

WriteUtf8NoBom $shareComp $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /r/[code] e teste:"
$log += "   - clicar nos botões de copiar -> aparece feedback e some ~1,2s"
$log += "   - Compartilhar texto -> deve mostrar 'Pronto!'"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 31 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] (toast Copiado!)" -ForegroundColor Yellow