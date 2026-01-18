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

$rep = NewReport "eco-step-38b-wire-day-share-link-and-smoke-safe"
$log = @()
$log += "# ECO — STEP 38b — Link público do dia no /operador/triagem + smoke /s/dia/HOJE + fix Next16 params/headers"
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

  if($txtP -match "function originFromHeaders"){
    if($txtP -notmatch "async function originFromHeaders"){
      $txtP = $txtP.Replace("function originFromHeaders()", "async function originFromHeaders()")
      $txtP = $txtP.Replace("function originFromHeaders(){", "async function originFromHeaders(){")
    }
    if($txtP -match "const h = headers\(" -and $txtP -notmatch "await headers\("){
      $txtP = $txtP.Replace("const h = headers();", "const h = await headers();")
      $txtP = $txtP.Replace("const h = headers()", "const h = await headers()")
    }
  }

  if($txtP -match "export async function generateMetadata"){
    if($txtP -match "const day = safeDay\(params\.day\);"){
      $txtP = $txtP.Replace("const day = safeDay(params.day);", "const p = await Promise.resolve(params);`n  const day = safeDay(p.day);")
    }
    if($txtP -match "const origin = originFromHeaders\(\);"){
      $txtP = $txtP.Replace("const origin = originFromHeaders();", "const origin = await originFromHeaders();")
    }
  }

  if($txtP -match "export default function Page"){
    $txtP = $txtP.Replace("export default function Page", "export default async function Page")
  }
  if($txtP -match "export default async function Page" -and $txtP -match "const day = safeDay\(params\.day\);"){
    $txtP = $txtP.Replace("const day = safeDay(params.day);", "const p = await Promise.resolve(params);`n  const day = safeDay(p.day);")
  }

  WriteUtf8NoBom $page $txtP
  $log += "- OK: /s/dia/[day]/page.tsx ajustado para Next16."
  $log += ""
} else {
  $log += "## INFO"
  $log += "Não achei src/app/s/dia/[day]/page.tsx (skip fix Next16)."
  $log += ""
}

# -------------------------
# B) UI: /operador/triagem -> botões do link público do dia
# -------------------------
$tri = "src/app/operador/triagem/OperatorTriageV2.tsx"
if(!(Test-Path -LiteralPath $tri)){
  $tri = FindFirst "." "\\src\\app\\operador\\triagem\\OperatorTriageV2\.tsx$"
}

if(!(Test-Path -LiteralPath $tri)){
  $log += "## WARN"
  $log += "Não achei OperatorTriageV2.tsx. Vou patchar só o eco-smoke."
  $log += ""
} else {
  $bkT = BackupFile $tri
  $txtT = Get-Content -LiteralPath $tri -Raw

  $log += "## PATCH — TRIAGEM"
  $log += ("Arquivo: {0}" -f $tri)
  $log += ("Backup : {0}" -f $bkT)

  if($txtT -notmatch "ECO_STEP38_DAY_SHARE_LINK_HELPERS_START"){
    $helperLines = @(
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
    )
    $helper = ($helperLines -join "`n")

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
    $uiLines = @(
      "          {/* ECO_STEP38_DAY_SHARE_LINK_UI_START */}",
      "          <button type=""button"" onClick={onOpenDaySharePage} style={{ padding: ""6px 10px"" }}>Página pública do dia</button>",
      "          <button type=""button"" onClick={onCopyDayShareLink} style={{ padding: ""6px 10px"" }}>Copiar link do dia</button>",
      "          <button type=""button"" onClick={onWaDayShareLink} style={{ padding: ""6px 10px"" }}>WhatsApp (link do dia)</button>",
      "          {/* ECO_STEP38_DAY_SHARE_LINK_UI_END */}"
    )
    $ui = ($uiLines -join "`n")

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
}

# -------------------------
# C) SMOKE: incluir /s/dia/$today e remover vírgulas finais que quebram parser
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
$txtS = Get-Content -LiteralPath $smoke -Raw
$log += "## PATCH — SMOKE"
$log += ("Arquivo: {0}" -f $smoke)
$log += ("Backup : {0}" -f $bkS)

$lines = $txtS -split "`n"
for($i=0; $i -lt $lines.Count; $i++){
  $lines[$i] = $lines[$i].TrimEnd("`r")
}

$start = -1
for($i=0; $i -lt $lines.Count; $i++){
  if($lines[$i] -match "^\s*\$Paths\s*=\s*@\(\s*$" -or $lines[$i] -match "^\s*\$paths\s*=\s*@\(\s*$"){
    $start = $i
    break
  }
}
if($start -lt 0){
  # fallback: tenta achar primeira linha com "@(" e variável Paths/paths em alguma forma
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "\$Paths" -and $lines[$i] -match "@\("){
      $start = $i
      break
    }
    if($lines[$i] -match "\$paths" -and $lines[$i] -match "@\("){
      $start = $i
      break
    }
  }
}

if($start -ge 0){
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\)\s*$"){
      $end = $j
      break
    }
  }

  if($end -gt $start){
    # garante $today acima do bloco
    $hasToday = $false
    for($k=0; $k -lt $lines.Count; $k++){
      if($lines[$k] -match "ECO_STEP38_SMOKE_TODAY_START"){ $hasToday = $true; break }
    }
    if(-not $hasToday){
      $ins = @(
        "# ECO_STEP38_SMOKE_TODAY_START",
        '$today = (Get-Date -Format "yyyy-MM-dd")',
        "# ECO_STEP38_SMOKE_TODAY_END",
        ""
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

    # normaliza: remove vírgula final de itens "/..."
    for($j=$start+1; $j -lt $end; $j++){
      $t = $lines[$j].TrimEnd()
      if($t -match "^\s*['""]\/.+['""]\s*,\s*$"){
        $lines[$j] = ($t -replace ",\s*$","")
      }
    }

    # insere /s/dia/$today se não existir
    $hasDay = $false
    $idxTri = -1
    for($j=$start+1; $j -lt $end; $j++){
      if($lines[$j] -match "/s/dia/"){ $hasDay = $true }
      if($lines[$j] -match "/operador/triagem"){ $idxTri = $j }
    }

    if(-not $hasDay){
      $newLine = '  "/s/dia/$today"'
      if($idxTri -ge 0){
        $before = $lines[0..$idxTri]
        $mid = @($newLine)
        $after = $lines[($idxTri+1)..($lines.Count-1)]
        $lines = @($before + $mid + $after)
        $log += '- OK: adicionei "/s/dia/$today" após /operador/triagem.'
      } else {
        # antes do fechamento do array
        $before = $lines[0..($end-1)]
        $mid = @($newLine)
        $after = $lines[$end..($lines.Count-1)]
        $lines = @($before + $mid + $after)
        $log += '- OK: adicionei "/s/dia/$today" antes do fechamento do array (fallback).'
      }
    } else {
      $log += "- INFO: já existe /s/dia/ no smoke (skip)."
    }
  } else {
    $log += "- WARN: não achei o fechamento do array @() do smoke (skip)."
  }
} else {
  $log += "- WARN: não achei o bloco `$Paths = @(` no smoke (skip)."
}

$txtS2 = ($lines -join "`n")
WriteUtf8NoBom $smoke $txtS2
$log += "- OK: eco-smoke.ps1 atualizado."
$log += ""

$log += "## VERIFY"
$log += "1) Reinicie o dev (se necessário): CTRL+C ; npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) /operador/triagem -> Fechamento do dia:"
$log += "   - Página pública do dia"
$log += "   - Copiar link do dia"
$log += "   - WhatsApp (link do dia)"
$log += "4) Abra /s/dia/$(Get-Date -Format yyyy-MM-dd)"

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 38b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "2) Teste /operador/triagem (Fechamento do dia -> link público)" -ForegroundColor Yellow
Write-Host ("3) Abra /s/dia/{0}" -f (Get-Date -Format yyyy-MM-dd)) -ForegroundColor Yellow