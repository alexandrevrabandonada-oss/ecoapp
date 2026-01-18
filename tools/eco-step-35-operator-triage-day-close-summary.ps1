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

$rep = NewReport "eco-step-35-operator-triage-day-close-summary"
$log = @()
$log += "# ECO — STEP 35 — /operador/triagem: Fechamento do dia (resumo + boletim copiar/WhatsApp)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$tri = "src/app/operador/triagem/OperatorTriageV2.tsx"
if(!(Test-Path -LiteralPath $tri)){
  $tri = FindFirst "." "\\src\\app\\operador\\triagem\\OperatorTriageV2\.tsx$"
}
if(!(Test-Path -LiteralPath $tri)){
  $log += "## ERRO"
  $log += "Não achei OperatorTriageV2.tsx"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei OperatorTriageV2.tsx"
}

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $tri)
$log += ""

$bk = BackupFile $tri
$txt = Get-Content -LiteralPath $tri -Raw

$log += "## PATCH"
$log += ("Backup: {0}" -f $bk)

if($txt -match "ECO_STEP35_DAY_CLOSE_START"){
  $log += "- INFO: STEP 35 já aplicado (marcador encontrado)."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 35 já aplicado (idempotente). Report -> {0}" -f $rep) -ForegroundColor Green
  exit 0
}

# 1) Inserir stats (após const visible = useMemo(...))
$anchorVisibleEnd = "}, [items, filter, onlyRouteDay, routeDay]);"
$posVis = $txt.IndexOf($anchorVisibleEnd)
if($posVis -lt 0){
  $log += "- WARN: não achei âncora do visible useMemo; vou tentar ancorar antes do token footer."
} else {
  $insertAt = $posVis + $anchorVisibleEnd.Length
  $stats = @"
// ECO_STEP35_DAY_CLOSE_START
  const dayStats = useMemo(() => {
    const dayItems = items.filter((it: any) => safeStr(it?.routeDay) === routeDay);
    const s: any = { total: dayItems.length, NEW: 0, IN_ROUTE: 0, DONE: 0, CANCELED: 0, OTHER: 0 };
    dayItems.forEach((it: any) => {
      const st = safeStr(it?.status) || "NEW";
      if (st === "NEW" || st === "IN_ROUTE" || st === "DONE" || st === "CANCELED") s[st] = (s[st] || 0) + 1;
      else s.OTHER = (s.OTHER || 0) + 1;
    });
    return s;
  }, [items, routeDay]);

  const dailyBulletinText = () => {
    const s: any = dayStats as any;
    const lines: string[] = [];
    lines.push("ECO — FECHAMENTO " + routeDay);
    lines.push("Total: " + String(s.total || 0));
    lines.push("NEW: " + String(s.NEW || 0));
    lines.push("IN_ROUTE: " + String(s.IN_ROUTE || 0));
    lines.push("DONE: " + String(s.DONE || 0));
    lines.push("CANCELED: " + String(s.CANCELED || 0));
    if (s.OTHER) lines.push("OUTROS: " + String(s.OTHER || 0));
    return lines.join("\n");
  };

  const onCopyDailyBulletin = () => {
    const text = dailyBulletinText();
    try {
      navigator.clipboard.writeText(text);
      alert("Boletim copiado.");
    } catch {
      alert(text);
    }
  };

  const onWaDailyBulletin = () => {
    const text = dailyBulletinText();
    const url = "https://wa.me/?text=" + encodeURIComponent(text);
    window.open(url, "_blank", "noopener,noreferrer");
  };
// ECO_STEP35_DAY_CLOSE_END
"@
  $txt = $txt.Insert($insertAt, "`n`n" + $stats + "`n")
  $log += "- OK: stats + boletim inseridos após visible useMemo."
}

# 2) Inserir UI do fechamento (antes do footer do token)
$needleFooter = "Token (localStorage):"
$idxFooter = $txt.IndexOf($needleFooter)
if($idxFooter -lt 0){
  $log += "- WARN: não achei footer do token; vou tentar inserir antes do </div> final."
  $idxFinal = $txt.LastIndexOf("</div>")
  if($idxFinal -gt 0){
    $panel = @"
      {/* ECO_STEP35_DAY_CLOSE_UI_START */}
      <div style={{ marginTop: 12, padding: 12, border: '1px solid #ddd', borderRadius: 8 }}>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          <b>Fechamento do dia</b>
          <span style={{ opacity: 0.8 }}>({routeDay})</span>
          <span style={{ marginLeft: 8, opacity: 0.9 }}>
            Total: {dayStats.total} • NEW: {dayStats.NEW} • IN_ROUTE: {dayStats.IN_ROUTE} • DONE: {dayStats.DONE} • CANCELED: {dayStats.CANCELED}{dayStats.OTHER ? (" • OUTROS: " + dayStats.OTHER) : ""}
          </span>
        </div>
        <div style={{ marginTop: 8, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button type="button" onClick={onCopyDailyBulletin} style={{ padding: '6px 10px' }}>Copiar boletim do dia</button>
          <button type="button" onClick={onWaDailyBulletin} style={{ padding: '6px 10px' }}>WhatsApp boletim</button>
        </div>
      </div>
      {/* ECO_STEP35_DAY_CLOSE_UI_END */}
"@
    $txt = $txt.Insert($idxFinal, $panel + "`n")
    $log += "- OK: painel de fechamento inserido antes do último </div>."
  } else {
    $log += "- WARN: não consegui inserir painel (sem âncora segura)."
  }
} else {
  # achar o começo do div do footer (a linha do <div style={{ marginTop: 14 ... }})
  $idxDiv = $txt.LastIndexOf("<div style={{ marginTop: 14", $idxFooter)
  if($idxDiv -lt 0){ $idxDiv = $idxFooter }
  $panel = @"
      {/* ECO_STEP35_DAY_CLOSE_UI_START */}
      <div style={{ marginTop: 12, padding: 12, border: '1px solid #ddd', borderRadius: 8 }}>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          <b>Fechamento do dia</b>
          <span style={{ opacity: 0.8 }}>({routeDay})</span>
          <span style={{ marginLeft: 8, opacity: 0.9 }}>
            Total: {dayStats.total} • NEW: {dayStats.NEW} • IN_ROUTE: {dayStats.IN_ROUTE} • DONE: {dayStats.DONE} • CANCELED: {dayStats.CANCELED}{dayStats.OTHER ? (" • OUTROS: " + dayStats.OTHER) : ""}
          </span>
        </div>
        <div style={{ marginTop: 8, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button type="button" onClick={onCopyDailyBulletin} style={{ padding: '6px 10px' }}>Copiar boletim do dia</button>
          <button type="button" onClick={onWaDailyBulletin} style={{ padding: '6px 10px' }}>WhatsApp boletim</button>
        </div>
      </div>
      {/* ECO_STEP35_DAY_CLOSE_UI_END */}
"@
  $txt = $txt.Insert($idxDiv, $panel + "`n")
  $log += "- OK: painel de fechamento inserido antes do footer do token."
}

WriteUtf8NoBom $tri $txt
$log += "- OK: arquivo salvo."

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev: npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /operador/triagem e teste:"
$log += "   - Ajustar 'Rota (dia)' e ver contadores do fechamento"
$log += "   - Copiar boletim do dia / WhatsApp boletim"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 35 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /operador/triagem (Fechamento do dia + boletim)" -ForegroundColor Yellow