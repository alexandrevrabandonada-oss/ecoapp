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
  if($null -eq $txt){ return "" }
  $pat = "(?s)//\s*" + [regex]::Escape($startMarker) + ".*?//\s*" + [regex]::Escape($endMarker) + "\s*`r?`n?"
  return [regex]::Replace($txt, $pat, "", "Multiline")
}
function RemoveJsxBlockByMarkers([string]$txt, [string]$startMarker, [string]$endMarker){
  if($null -eq $txt){ return "" }
  $pat = "(?s)\{\s*/\*\s*" + [regex]::Escape($startMarker) + "\s*\*/\s*\}.*?\{\s*/\*\s*" + [regex]::Escape($endMarker) + "\s*\*/\s*\}\s*"
  return [regex]::Replace($txt, $pat, "", "Multiline")
}

$rep = NewReport "eco-step-32b-operator-triage-route-of-day-safe"
$log = @()
$log += "# ECO — STEP 32b — Rota do dia SAFE no /operador/triagem (sem aspas curvas)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$board = "src/components/eco/OperatorTriageBoard.tsx"
if(!(Test-Path -LiteralPath $board)){
  $board = FindFirst "." "\\src\\components\\eco\\OperatorTriageBoard\.tsx$"
}
if(!(Test-Path -LiteralPath $board)){
  $log += "## ERRO"
  $log += "Não achei src/components/eco/OperatorTriageBoard.tsx"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei OperatorTriageBoard.tsx"
}

$bk = BackupFile $board
$txt = Get-Content -LiteralPath $board -Raw
if($null -eq $txt){ $txt = "" }

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $board)
$log += ("Backup : {0}" -f $bk)
$log += ""

$log += "## PATCH"

# idempotência: remove blocos anteriores
$txt = RemoveBlockByMarkers $txt "ECO_STEP32_ROUTE_DAY_START" "ECO_STEP32_ROUTE_DAY_END"
$txt = RemoveJsxBlockByMarkers $txt "ECO_STEP32_ROUTE_UI_START" "ECO_STEP32_ROUTE_UI_END"

# 1) inserir helpers
$helpers = @"
// ECO_STEP32_ROUTE_DAY_START
// Rota do dia: bairro + so NOVOS + copiar/WhatsApp

function eco32ClipboardWrite(text: string): Promise<void> {
  try {
    const nav: any = navigator as any;
    if (nav?.clipboard?.writeText) return nav.clipboard.writeText(text);
  } catch {}
  return new Promise((resolve, reject) => {
    try {
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      ta.style.left = '-9999px';
      document.body.appendChild(ta);
      ta.focus();
      ta.select();
      const ok = document.execCommand('copy');
      ta.remove();
      if (ok) resolve();
      else reject(new Error('clipboard failed'));
    } catch (e) {
      reject(e as any);
    }
  });
}

function eco32BuildRouteText(items: AnyObj[]): string {
  const now = new Date();
  const stamp = now.toLocaleString();
  const lines: string[] = [];
  lines.push('🧾 ECO — Rota do dia');
  lines.push('📅 ' + stamp);
  lines.push('📦 Pedidos: ' + String(items.length));
  lines.push('');

  const by = new Map<string, AnyObj[]>();
  for (const it of items) {
    const bairro = eco31Get(it, ['bairro','neighborhood','district','regiao','região','area','local']).trim() || '(sem bairro)';
    const arr = by.get(bairro) ?? [];
    arr.push(it);
    by.set(bairro, arr);
  }

  const bairros = Array.from(by.keys()).sort((a, b) => a.localeCompare(b));
  for (const b of bairros) {
    lines.push('📍 ' + b + ' — ' + String(by.get(b)?.length ?? 0));
    const arr = by.get(b) ?? [];
    for (const it of arr) {
      const id = eco31Id(it);
      const nome = eco31Get(it, ['name','nome','contactName','responsavel','responsável']);
      const tel  = eco31Get(it, ['phone','telefone','tel','cel','whatsapp','zap','contactPhone']);
      const end  = eco31Get(it, ['address','endereco','endereço','rua','logradouro','street','location']);
      const itens = eco31Get(it, ['items','itens','materials','materiais','bag','bags','sacos','observacao','observação','notes','note']);
      const parts = [
        '• ' + (end || '(sem endereco)'),
        (nome || tel) ? ('— ' + [nome, tel].filter(Boolean).join(' • ')) : '',
        itens ? ('— itens: ' + itens) : '',
        id ? ('— id: ' + id) : '',
      ].filter(Boolean);
      lines.push(parts.join(' '));
    }
    lines.push('');
  }

  lines.push('—');
  lines.push('Assinatura ECO');
  return lines.join('\n');
}

function eco32WhatsAppUrl(text: string): string {
  return 'https://wa.me/?text=' + encodeURIComponent(text);
}
// ECO_STEP32_ROUTE_DAY_END
"@

# tenta inserir depois de eco31Status; fallback: após 'use client'; fallback topo
$insertedHelpers = $false
$reEco31 = [regex]::new("function\s+eco31Status[\s\S]*?\r?\n\}", "Multiline")
$mEco31 = $reEco31.Match($txt)
if($mEco31.Success){
  $pos = $mEco31.Index + $mEco31.Length
  $txt = $txt.Insert($pos, "`n`n" + $helpers + "`n")
  $insertedHelpers = $true
  $log += "- OK: helpers inseridos após eco31Status."
}
if(-not $insertedHelpers){
  $idxUC = $txt.IndexOf("'use client'")
  if($idxUC -ge 0){
    $nl = $txt.IndexOf("`n", $idxUC)
    if($nl -gt 0){
      $txt = $txt.Insert($nl+1, "`n`n" + $helpers + "`n")
      $insertedHelpers = $true
      $log += "- OK: helpers inseridos após 'use client' (fallback)."
    }
  }
}
if(-not $insertedHelpers){
  $txt = $helpers + "`n" + $txt
  $log += "- OK: helpers inseridos no topo (fallback)."
}

# 2) state
if($txt -notmatch "const\s+\[routeBairro,\s*setRouteBairro\]"){
  $reState = [regex]::new("const\s+\[showOther,\s*setShowOther\][\s\S]*?;\s*", "Multiline")
  $mState = $reState.Match($txt)
  if($mState.Success){
    $pos = $mState.Index + $mState.Length
    $state = @"
  const [routeBairro, setRouteBairro] = useState<string>('');
  const [routeOnlyNew, setRouteOnlyNew] = useState<boolean>(true);
"@
    $txt = $txt.Insert($pos, "`n" + $state)
    $log += "- OK: state routeBairro/routeOnlyNew inserido."
  } else {
    $log += "- WARN: não achei showOther para ancorar state; skip."
  }
} else {
  $log += "- INFO: state de rota já existe (skip)."
}

# 3) derivados + handlers (após cols)
if($txt -notmatch "routeCandidates"){
  $needle = "const cols = useMemo(() => pickColumns(filtered), [filtered]);"
  $idxCols = $txt.IndexOf($needle)
  if($idxCols -ge 0){
    $after = $idxCols + $needle.Length
    $insert = @"
  
  const bairrosAll = useMemo(() => {
    const set = new Set<string>();
    for (const it of items) {
      const b = eco31Get(it, ['bairro','neighborhood','district','regiao','região','area','local']).trim();
      if (b) set.add(b);
    }
    return Array.from(set).sort((a, b) => a.localeCompare(b));
  }, [items]);

  const routeCandidates = useMemo(() => {
    let arr: AnyObj[] = filtered;
    if (routeOnlyNew) {
      arr = arr.filter((it) => (COL_NEW as readonly string[]).includes(eco31Status(it)));
    }
    if (routeBairro.trim()) {
      const rb = routeBairro.trim();
      arr = arr.filter((it) => eco31Get(it, ['bairro','neighborhood','district','regiao','região','area','local']).trim() === rb);
    }
    return arr;
  }, [filtered, routeOnlyNew, routeBairro]);

  const routeText = useMemo(() => eco32BuildRouteText(routeCandidates), [routeCandidates]);

  const onCopyRoute = async () => {
    try {
      await eco32ClipboardWrite(routeText);
      alert('✅ Rota copiada!');
    } catch {
      alert('⚠️ Não consegui copiar automaticamente. Abra o "ver texto da rota" e copie manualmente.');
    }
  };

  const onWhatsAppRoute = () => {
    const url = eco32WhatsAppUrl(routeText);
    window.open(url, '_blank', 'noopener,noreferrer');
  };
"@
    $txt = $txt.Insert($after, $insert)
    $log += "- OK: derivados/handlers de rota inseridos."
  } else {
    $log += "- WARN: não achei linha do cols para ancorar derivados; skip."
  }
} else {
  $log += "- INFO: routeCandidates já existe (skip derivados)."
}

# 4) UI: inserir logo após o primeiro tag do return (robusto, sem depender de texto)
if($txt -notmatch "ECO_STEP32_ROUTE_UI_START"){
  $idxReturn = $txt.IndexOf("return (")
  if($idxReturn -lt 0){ $idxReturn = $txt.IndexOf("return(") }

  if($idxReturn -ge 0){
    $idxTag = $txt.IndexOf("<", $idxReturn)
    if($idxTag -ge 0){
      $insertPos = -1
      $two = ""
      if($idxTag + 1 -lt $txt.Length){
        $two = $txt.Substring($idxTag, [Math]::Min(2, $txt.Length - $idxTag))
      }

      if($two -eq "<>"){
        $insertPos = $idxTag + 2
      } else {
        $idxGt = $txt.IndexOf(">", $idxTag)
        if($idxGt -gt 0){
          $insertPos = $idxGt + 1
        }
      }

      if($insertPos -gt 0){
        $ui = @"
        {/* ECO_STEP32_ROUTE_UI_START */}
        <div className="mt-3 rounded border bg-white p-3">
          <div className="flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
            <div>
              <div className="text-sm font-semibold">Rota do dia</div>
              <div className="text-xs opacity-70">Filtra por bairro e gera texto pronto pra copiar/WhatsApp.</div>
            </div>

            <div className="flex flex-col gap-2 md:flex-row md:items-end">
              <div>
                <label className="text-sm font-semibold">Bairro</label>
                <select
                  value={routeBairro}
                  onChange={(e) => setRouteBairro(e.target.value)}
                  className="mt-1 w-full rounded border px-3 py-2"
                >
                  <option value="">(todos)</option>
                  {bairrosAll.map((b) => (
                    <option key={b} value={b}>{b}</option>
                  ))}
                </select>
              </div>

              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" checked={routeOnlyNew} onChange={(e) => setRouteOnlyNew(e.target.checked)} />
                so NOVOS
              </label>

              <div className="flex gap-2">
                <button type="button" onClick={onCopyRoute} className="rounded bg-black px-3 py-2 text-white">
                  Copiar rota
                </button>
                <button type="button" onClick={onWhatsAppRoute} className="rounded border px-3 py-2">
                  WhatsApp
                </button>
              </div>
            </div>
          </div>

          <div className="mt-2 text-xs opacity-70">
            Itens na rota: <span className="font-mono">{routeCandidates.length}</span>
          </div>

          <details className="mt-2">
            <summary className="cursor-pointer text-xs underline">ver texto da rota</summary>
            <pre className="mt-2 max-h-80 overflow-auto whitespace-pre-wrap break-words rounded border bg-gray-50 p-2 text-[11px]">{routeText}</pre>
          </details>
        </div>
        {/* ECO_STEP32_ROUTE_UI_END */}
"@
        $txt = $txt.Insert($insertPos, "`n" + $ui + "`n")
        $log += "- OK: UI 'Rota do dia' inserida no return."
      } else {
        $log += "- WARN: não consegui achar posição segura pra inserir UI no return (skip UI)."
      }
    } else {
      $log += "- WARN: não achei '<' após return (skip UI)."
    }
  } else {
    $log += "- WARN: não achei return( / return ( (skip UI)."
  }
} else {
  $log += "- INFO: UI já existe (skip UI)."
}

WriteUtf8NoBom $board $txt
$log += "- OK: OperatorTriageBoard atualizado."

# 5) smoke: tentar adicionar /operador/triagem
$smoke = "tools/eco-smoke.ps1"
if(!(Test-Path -LiteralPath $smoke)){
  $smoke = FindFirst "." "\\tools\\eco-smoke\.ps1$"
}
if($smoke -and (Test-Path -LiteralPath $smoke)){
  $log += ""
  $log += "## PATCH (smoke)"
  $log += ("Arquivo: {0}" -f $smoke)
  $log += ("Backup : {0}" -f (BackupFile $smoke))

  $s = Get-Content -LiteralPath $smoke -Raw
  if($null -eq $s){ $s = "" }

  if($s -match "/operador/triagem"){
    $log += "- INFO: /operador/triagem já está no smoke (skip)."
  } else {
    # tenta inserir após /recibos
    $idx = $s.IndexOf("/recibos")
    if($idx -ge 0){
      $lineEnd = $s.IndexOf("`n", $idx)
      if($lineEnd -lt 0){ $lineEnd = $s.Length }
      $insLine = "  '/operador/triagem',"
      $s = $s.Insert($lineEnd, "`n" + $insLine)
      WriteUtf8NoBom $smoke $s
      $log += "- OK: inseri /operador/triagem no eco-smoke."
    } else {
      $log += "- WARN: não achei /recibos pra ancorar no smoke (skip)."
    }
  }
}

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /operador/triagem e teste Rota do dia (bairro + so NOVOS + copiar + WhatsApp)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 32b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /operador/triagem (Rota do dia: copiar/WhatsApp)" -ForegroundColor Yellow