$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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
function FindFirstFileLike([string]$root, [string]$endsWith){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName.Replace('\','/').ToLower().EndsWith($endsWith.ToLower()) } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport "eco-step-45-triagem-shortcut-s-dia"
$log = @()
$log += "# ECO — STEP 45 — Atalho /s/dia dentro do /operador/triagem"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  # GUARD: repo certo?
  if(!(Test-Path -LiteralPath "src/app/s/dia")){
    throw "GUARD: não achei src/app/s/dia. Rode no repo ECO (C:\Projetos\App ECO\eluta-servicos)."
  }

  $triagePage = "src/app/operador/triagem/page.tsx"
  if(!(Test-Path -LiteralPath $triagePage)){
    $triagePage = FindFirstFileLike "src/app" "/operador/triagem/page.tsx"
  }
  if(!$triagePage){
    throw "Não achei a página do operador/triagem (page.tsx)."
  }

  $log += "## DIAG"
  $log += ("Triagem page: {0}" -f $triagePage)
  $log += ""

  # PATCH 1) criar componente DayCloseShortcut
  $compPath = (Join-Path (Split-Path -Parent $triagePage) "DayCloseShortcut.tsx")
  $bkComp = BackupFile $compPath
  EnsureDir (Split-Path -Parent $compPath)

  $compTxt = @"
"use client";

type ShareNav = Navigator & {
  share?: (data: ShareData) => Promise<void>;
  canShare?: (data: ShareData) => boolean;
};

function todaySP(): string {
  try {
    const fmt = new Intl.DateTimeFormat("en-CA", {
      timeZone: "America/Sao_Paulo",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    return fmt.format(new Date());
  } catch {
    const d = new Date();
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    const dd = String(d.getDate()).padStart(2, "0");
    return yyyy + "-" + mm + "-" + dd;
  }
}

function linkFor(day: string) {
  const v = String(day || "").trim() || todaySP();
  return window.location.origin + "/s/dia/" + encodeURIComponent(v);
}

export default function DayCloseShortcut() {
  const day = todaySP();

  const open = () => {
    window.location.href = "/s/dia/" + encodeURIComponent(day);
  };

  const copy = async () => {
    const link = linkFor(day);
    try {
      await navigator.clipboard.writeText(link);
      alert("Link do fechamento copiado!");
    } catch {
      prompt("Copie o link:", link);
    }
  };

  const wa = () => {
    const link = linkFor(day);
    const text = "ECO — Fechamento do dia " + day + "\n" + link;
    window.open("https://wa.me/?text=" + encodeURIComponent(text), "_blank", "noopener,noreferrer");
  };

  const share = async () => {
    const nav = navigator as ShareNav;
    const url = linkFor(day);
    const data: ShareData = { title: "ECO — Fechamento do dia " + day, text: "ECO — Fechamento do dia " + day, url };
    if (nav.share && (!nav.canShare || nav.canShare(data))) {
      await nav.share(data);
      return;
    }
    await copy();
  };

  return (
    <section style={{ marginTop: 12, border: "1px solid #222", borderRadius: 14, padding: 12 }}>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, justifyContent: "space-between", alignItems: "baseline" }}>
        <div>
          <div style={{ fontWeight: 900 }}>Fechamento do dia</div>
          <div style={{ fontSize: 12, opacity: 0.75 }}>{day} • /s/dia/{day}</div>
        </div>
        <a href="/s/dia" style={{ fontSize: 12, opacity: 0.85, textDecoration: "underline" }}>
          Índice /s/dia
        </a>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, marginTop: 10 }}>
        <button type="button" onClick={open} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Abrir hoje
        </button>
        <button type="button" onClick={copy} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Copiar link
        </button>
        <button type="button" onClick={wa} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          WhatsApp
        </button>
        <button type="button" onClick={share} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Share Sheet
        </button>
      </div>

      <div style={{ marginTop: 10, fontSize: 12, opacity: 0.75 }}>
        Recibo é lei. Cuidado é coletivo. Trabalho digno é o centro.
      </div>
    </section>
  );
}
"@

  WriteUtf8NoBom $compPath $compTxt
  $log += "## PATCH — componente"
  $log += ("Arquivo: {0}" -f $compPath)
  $log += ("Backup : {0}" -f ($(if($bkComp){$bkComp}else{"(novo)"})))
  $log += "- OK: DayCloseShortcut criado."
  $log += ""

  # PATCH 2) inserir no page.tsx do /operador/triagem
  $raw = Get-Content -LiteralPath $triagePage -Raw
  $bkPage = BackupFile $triagePage

  if(!$raw.Contains("DayCloseShortcut")){
    # inserir import antes do export default (best effort)
    if(!$raw.Contains('import DayCloseShortcut from "./DayCloseShortcut";')){
      $pos = $raw.IndexOf("export default")
      if($pos -gt 0){
        $raw = $raw.Insert($pos, 'import DayCloseShortcut from "./DayCloseShortcut";' + "`n")
      } else {
        $raw = 'import DayCloseShortcut from "./DayCloseShortcut";' + "`n" + $raw
      }
    }

    # inserir render logo após abrir <main ...>
    if(!$raw.Contains("<DayCloseShortcut")){
      $ix = $raw.IndexOf("<main")
      if($ix -ge 0){
        $gt = $raw.IndexOf(">", $ix)
        if($gt -ge 0){
          $insertPos = $gt + 1
          $raw = $raw.Insert($insertPos, "`n      <DayCloseShortcut />`n")
        }
      } else {
        # fallback: após "return ("
        $ret = $raw.IndexOf("return (")
        if($ret -ge 0){
          $ins = $ret + ("return (").Length
          $raw = $raw.Insert($ins, "`n      <DayCloseShortcut />`n")
        }
      }
    }

    WriteUtf8NoBom $triagePage $raw
    $log += "## PATCH — triagem page"
    $log += ("Arquivo: {0}" -f $triagePage)
    $log += ("Backup : {0}" -f $bkPage)
    $log += "- OK: DayCloseShortcut inserido (best effort)."
    $log += ""
  } else {
    $log += "## INFO"
    $log += "- triagem page já contém DayCloseShortcut; skip."
    $log += ""
  }

  # PATCH 3) (opcional) link de volta na /s/dia/[day] page (best effort)
  $dayPage = "src/app/s/dia/[day]/page.tsx"
  if(Test-Path -LiteralPath $dayPage){
    $d = Get-Content -LiteralPath $dayPage -Raw
    if(!$d.Contains('href="/operador/triagem"')){
      $bkD = BackupFile $dayPage
      $ix2 = $d.IndexOf("<main")
      if($ix2 -ge 0){
        $gt2 = $d.IndexOf(">", $ix2)
        if($gt2 -ge 0){
          $d = $d.Insert($gt2 + 1, "`n      <p style={{ marginTop: 8, marginBottom: 8 }}><a href=""/operador/triagem"" style={{ textDecoration: ""underline"" }}>← Voltar para Triagem</a></p>`n")
          WriteUtf8NoBom $dayPage $d
          $log += "## PATCH — /s/dia/[day]/page.tsx"
          $log += ("Backup : {0}" -f $bkD)
          $log += "- OK: link de volta para triagem inserido."
          $log += ""
        }
      }
    }
  }

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 45 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) npm run dev" -ForegroundColor Yellow
  Write-Host "2) Abra /operador/triagem (deve aparecer 'Fechamento do dia')" -ForegroundColor Yellow
  Write-Host "3) Clique 'Abrir hoje' -> /s/dia/AAAA-MM-DD" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}