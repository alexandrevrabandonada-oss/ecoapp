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

$rep = NewReport "eco-step-38c-wire-day-share-link-and-smoke-safe"
$log = @()
$log += "# ECO — STEP 38c — Link público do dia + smoke /s/dia/HOJE + fix Next16 params/headers"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# -------------------------
# A) FIX Next16: /s/dia/[day]/page.tsx (params e headers async)
# -------------------------
$page = "src/app/s/dia/[day]/page.tsx"
if(!(Test-Path -LiteralPath $page)){
  $page = FindFirst "." "\\src\\app\\s\\dia\\\[day\]\\page\.tsx$"
}

if(Test-Path -LiteralPath $page){
  $bkP = BackupFile $page
  $txtP = Get-Content -LiteralPath $page -Raw

  $log += "## PATCH — /s/dia/[day]/page.tsx (Next16 async params/headers)"
  $log += ("Arquivo: {0}" -f $page)
  $log += ("Backup : {0}" -f $bkP)

  if($txtP.Contains("function originFromHeaders()")){
    $txtP = $txtP.Replace("function originFromHeaders()", "async function originFromHeaders()")
  }
  if($txtP.Contains("const h = headers();")){
    $txtP = $txtP.Replace("const h = headers();", "const h = await headers();")
  }

  if($txtP.Contains("export async function generateMetadata") -and $txtP.Contains("const day = safeDay(params.day);")){
    $txtP = $txtP.Replace("const day = safeDay(params.day);", "const p = await Promise.resolve(params);`n  const day = safeDay(p.day);")
  }
  if($txtP.Contains("export async function generateMetadata") -and $txtP.Contains("const origin = originFromHeaders();")){
    $txtP = $txtP.Replace("const origin = originFromHeaders();", "const origin = await originFromHeaders();")
  }

  if($txtP.Contains("export default function Page")){
    $txtP = $txtP.Replace("export default function Page", "export default async function Page")
  }
  if($txtP.Contains("export default async function Page") -and $txtP.Contains("const day = safeDay(params.day);")){
    $txtP = $txtP.Replace("const day = safeDay(params.day);", "const p = await Promise.resolve(params);`n  const day = safeDay(p.day);")
  }

  WriteUtf8NoBom $page $txtP
  $log += "- OK: ajustado para Next16 (params/headers async)."
  $log += ""
} else {
  $log += "## INFO"
  $log += "Não achei /s/dia/[day]/page.tsx (skip)."
  $log += ""
}

# -------------------------
# B) UI: /operador/triagem -> botões do link público do dia
# -------------------------
$tri = "src/app/operador/triagem/OperatorTriageV2.tsx"
if(!(Test-Path -LiteralPath $tri)){
  $tri = FindFirst "." "\\src\\app\\operador\\triagem\\OperatorTriageV2\.tsx$"
}

if(Test-Path -LiteralPath $tri){
  $bkT = BackupFile $tri
  $txtT = Get-Content -LiteralPath $tri -Raw

  $log += "## PATCH — TRIAGEM"
  $log += ("Arquivo: {0}" -f $tri)
  $log += ("Backup : {0}" -f $bkT)

  if($txtT -notmatch "ECO_STEP38_DAY_SHARE_LINK_HELPERS_START"){
    $helper = @(
      "/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_START */",
      "const ecoDayPublicSharePath = () => `/s/dia/${encodeURIComponent(routeDay)}`;",
      "const ecoDayPublicShareUrl = () => {",
      "  try {",
      "    const base = window.location.origin;",
      "    return base + ecoDayPublicSharePath();",
      "  } catch {",
      "    return ecoDayPublicSharePath();",
      "  }",
      "};",
      "",
      "const onOpenDaySharePage = () => {",
      "  window.open(ecoDayPublicSharePath(), ""_blank"", ""noopener,noreferrer"");",
      "};",
      "",
      "const onCopyDayShareLink = async () => {",
      "  const link = ecoDayPublicShareUrl();",
      "  try {",
      "    await navigator.clipboard.writeText(link);",
      "    alert(""Link copiado!"");",
      "  } catch {",
      "    prompt(""Copie o link:"", link);",
      "  }",
      "};",
      "",
      "const onWaDayShareLink = () => {",
      "  const link = ecoDayPublicShareUrl();",
      "  const text = `ECO — Fechamento do dia ${routeDay}\\n${link}`;",
      "  const wa = `https://wa.me/?text=${encodeURIComponent(text)}`;",
      "  window.open(wa, ""_blank"", ""noopener,noreferrer"");",
      "};",
      "/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_END */"
    ) -join "`n"

    $anchorA = "ECO_STEP36_DAY_CARD_HELPERS_END"
    $idxA = $txtT.IndexOf($anchorA)
    if($idxA -ge 0){
      $idxNL = $txtT.IndexOf("`n", $idxA)
      if($idxNL -gt 0){
        $txtT = $txtT.Insert($idxNL+1, "`n" + $helper + "`n")
        $log += "- OK: helpers STEP 38 inseridos após STEP 36."
      } else {
        $txtT = $helper + "`n" + $txtT
        $log += "- OK: helpers STEP 38 inseridos no topo (fallback)."
      }
    } else {
      $anchorB = "ECO_STEP35_DAY_CLOSE_END"
      $idxB = $txtT.IndexOf($anchorB)
      if($idxB -ge 0){
        $idxNL2 = $txtT.IndexOf("`n", $idxB)
        if($idxNL2 -gt 0){
          $txtT = $txtT.Insert($idxNL2+1, "`n" + $helper + "`n")
          $log += "- OK: helpers STEP 38 inseridos após STEP 35."
        } else {
          $txtT = $helper + "`n" + $txtT
          $log += "- OK: helpers STEP 38 inseridos no topo (fallback)."
        }
      } else {
        $txtT = $helper + "`n" + $txtT
        $log += "- OK: helpers STEP 38 inseridos no topo (fallback)."
      }
    }
  } else {
    $log += "- INFO: helpers STEP 38 já existem (skip)."
  }

  if($txtT -notmatch "ECO_STEP38_DAY_SHARE_LINK_UI_START"){
    $ui = @(
      "          {/* ECO_STEP38_DAY_SHARE_LINK_UI_START */}",
      "          <button type=""button"" onClick={onOpenDaySharePage} style={{ padding: ""6px 10px"" }}>Página pública do dia</button>",
      "          <button type=""button"" onClick={onCopyDayShareLink} style={{ padding: ""6px 10px"" }}>Copiar link do dia</button>",
      "          <button type=""button"" onClick={onWaDayShareLink} style={{ padding: ""6px 10px"" }}>WhatsApp (link do dia)</button>",
      "          {/* ECO_STEP38_DAY_SHARE_LINK_UI_END */}"
    ) -join "`n"

    $anchorUI = "ECO_STEP36_DAY_CARD_UI_END"
    $idxUI = $txtT.IndexOf($anchorUI)
    if($idxUI -ge 0){
      $idxNLu = $txtT.IndexOf("`n", $idxUI)
      if($idxNLu -gt 0){
        $txtT = $txtT.Insert($idxNLu+1, "`n" + $ui + "`n")
        $log += "- OK: UI STEP 38 inserida após UI do STEP 36."
      } else {
        $log += "- WARN: achei âncora STEP 36 mas não achei quebra de linha (skip UI)."
      }
    } else {
      $needle = "onClick={onWaDailyBulletin}"
      $idxN = $txtT.IndexOf($needle)
      if($idxN -ge 0){
        $idxBtnEnd = $txtT.IndexOf("</button>", $idxN)
        if($idxBtnEnd -gt 0){
          $insertPos = $idxBtnEnd + 9
          $txtT = $txtT.Insert($insertPos, "`n" + $ui + "`n")
          $log += "- OK: UI STEP 38 inserida após botão do boletim (fallback)."
        } else {
          $log += "- WARN: achei onWaDailyBulletin mas não achei </button> (skip UI)."
        }
      } else {
        $log += "- WARN: não achei âncora para inserir UI STEP 38 (skip UI)."
      }
    }
  } else {
    $log += "- INFO: UI STEP 38 já existe (skip)."
  }

  WriteUtf8NoBom $tri $txtT
  $log += "- OK: OperatorTriageV2.tsx atualizado."
  $log += ""
} else {
  $log += "## WARN"
  $log += "Não achei OperatorTriageV2.tsx (skip UI)."
  $log += ""
}

# -------------------------
# C) SMOKE: incluir /s/dia/$today + remover vírgulas finais dentro do array
# -------------------------
$smoke = "tools/eco-smoke.ps1"
if(!(Test-Path -LiteralPath $smoke)){
  $smoke = FindFirst "." "\\tools\\eco-smoke\.ps1$"
}
if(!(Test-Path -LiteralPath $smoke)){
  $log += "## ERRO"
  $log += "Não achei tools/eco-smoke.ps1"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei eco-smoke.ps1"
}

$bkS = BackupFile $smoke
$raw = Get-Content -LiteralPath $smoke -Raw
$lines = $raw -split "`n"
for($i=0; $i -lt $lines.Count; $i++){ $lines[$i] = $lines[$i].TrimEnd("`r") }

$log += "## PATCH — SMOKE"
$log += ("Arquivo: {0}" -f $smoke)
$log += ("Backup : {0}" -f $bkS)

$start = -1
for($i=0; $i -lt $lines.Count; $i++){
  $ln = $lines[$i]
  if( ($ln.Contains('$Paths') -or $ln.Contains('$paths')) -and $ln.Contains('@(') ){
    $start = $i
    break
  }
}

if($start -lt 0){
  $log += "- WARN: não achei a linha do `$Paths = @(` (skip patch paths)."
} else {
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j].Trim() -eq ')'){ $end = $j; break }
  }

  if($end -lt 0){
    $log += "- WARN: não achei o fechamento ')' do array de paths (skip patch paths)."
  } else {
    $hasToday = $false
    for($k=0; $k -lt $lines.Count; $k++){
      if($lines[$k].Contains('ECO_STEP38_SMOKE_TODAY_START')){ $hasToday = $true; break }
    }
    if(-not $hasToday){
      $ins = @(
        '# ECO_STEP38_SMOKE_TODAY_START',
        '$today = (Get-Date -Format "yyyy-MM-dd")',
        '# ECO_STEP38_SMOKE_TODAY_END',
        ''
      )
      $before = @()
      if($start -gt 0){ $before = $lines[0..($start-1)] }
      $after = $lines[$start..($lines.Count-1)]
      $lines = @($before + $ins + $after)

      $start = $start + $ins.Count
      $end = $end + $ins.Count
      $log += "- OK: inseri `$today antes do bloco de paths."
    } else {
      $log += "- INFO: `$today já existe (skip)."
    }

    # remove vírgulas finais de itens do array
    for($j=$start+1; $j -lt $end; $j++){
      $t = $lines[$j].TrimEnd()
      if($t.EndsWith(',')){
        $lines[$j] = $t.Substring(0, $t.Length-1)
      }
    }

    # inserir /s/dia/$today
    $hasDay = $false
    $idxTri = -1
    for($j=$start+1; $j -lt $end; $j++){
      if($lines[$j].Contains('/s/dia/')){ $hasDay = $true }
      if($lines[$j].Contains('/operador/triagem')){ $idxTri = $j }
    }

    if(-not $hasDay){
      $newLine = '  "/s/dia/$today"'
      if($idxTri -ge 0){
        $before = $lines[0..$idxTri]
        $after  = $lines[($idxTri+1)..($lines.Count-1)]
        $lines = @($before + @($newLine) + $after)
        $log += '- OK: adicionei "/s/dia/$today" após /operador/triagem.'
      } else {
        $before = $lines[0..($end-1)]
        $after  = $lines[$end..($lines.Count-1)]
        $lines = @($before + @($newLine) + $after)
        $log += '- OK: adicionei "/s/dia/$today" antes do fechamento do array (fallback).'
      }
    } else {
      $log += "- INFO: já existe /s/dia/ no smoke (skip)."
    }
  }
}

$patched = ($lines -join "`n")
WriteUtf8NoBom $smoke $patched
$log += "- OK: eco-smoke.ps1 atualizado."
$log += ""

$log += "## VERIFY"
$log += "1) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "2) Abra /operador/triagem e teste botões do link público"
$log += "3) Abra /s/dia/$(Get-Date -Format yyyy-MM-dd)"

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 38c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "2) Teste /operador/triagem (Fechamento do dia -> link público)" -ForegroundColor Yellow
Write-Host ("3) Abra /s/dia/{0}" -f (Get-Date -Format yyyy-MM-dd)) -ForegroundColor Yellow