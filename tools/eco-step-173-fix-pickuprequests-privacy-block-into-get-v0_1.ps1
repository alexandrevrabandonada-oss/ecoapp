param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

function TryDotSourceBootstrap([string]$root) {
  $boot = Join-Path $root "tools\_bootstrap.ps1"
  if (Test-Path $boot) { . $boot; return $true }
  return $false
}

function EnsureDir([string]$p) { if (!(Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

function WriteUtf8NoBom([string]$path, [string]$content) {
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $enc)
}

function BackupFile([string]$path, [string]$backupDir) {
  EnsureDir $backupDir
  $name = Split-Path $path -Leaf
  $dest = Join-Path $backupDir $name
  Copy-Item -Force $path $dest
  return $dest
}

function GetMinIndent([string[]]$lines) {
  $min = 999999
  foreach ($l in $lines) {
    if ($l -match "^\s*$") { continue }
    if ($l -match "^([ \t]+)") {
      $len = $Matches[1].Length
      if ($len -lt $min) { $min = $len }
    } else {
      $min = 0
      break
    }
  }
  if ($min -eq 999999) { return 0 }
  return $min
}

function IndentBlock([string]$block, [string]$insideIndent, [string]$nl) {
  $lines = ($block -split "\r?\n")
  $minIndent = GetMinIndent $lines
  $rebuilt = @()
  foreach ($l in $lines) {
    if ($l -match "^\s*$") { $rebuilt += $insideIndent.TrimEnd(); continue }
    $cut = $l
    if ($minIndent -gt 0 -and $cut.Length -ge $minIndent) { $cut = $cut.Substring($minIndent) }
    $rebuilt += ($insideIndent + $cut)
  }
  return ($rebuilt -join $nl)
}

function ParseFirstParamName([string]$args) {
  # pega o primeiro identificador (antes de : , ) ou espaço)
  $t = $args.Trim()
  if ($t -match "^\s*([A-Za-z_]\w*)") { return $Matches[1] }
  return "req"
}

function FindMatchingOpenParenBackward([string]$s, [int]$closeParenIdx) {
  $depth = 0
  for ($i = # close idx inclusive
       $i -ge 0
       $i--) { }
}

# --- root ---
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Resolve-Path (Join-Path $here "..")
$root = $root.Path

$hasBoot = TryDotSourceBootstrap $root
if ($hasBoot) {
  # se existir no bootstrap, sobrescreve helpers locais pelos oficiais
  if (Get-Command EnsureDir -ErrorAction SilentlyContinue) { }
  if (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue) { }
  if (Get-Command BackupFile -ErrorAction SilentlyContinue) { }
}

$target = Join-Path $root "src\app\api\pickup-requests\route.ts"
if (!(Test-Path $target)) { throw "Alvo nao encontrado: $target" }

$raw = Get-Content -Raw -Path $target
$nl = "`r`n"
if ($raw -notmatch "`r`n") { $nl = "`n" }

$startMarker = "// ECO_PICKUP_RECEIPT_PRIVACY_START"
$endMarker   = "// ECO_PICKUP_RECEIPT_PRIVACY_END"

$si = $raw.IndexOf($startMarker)
$ei = -1
if ($si -ge 0) { $ei = $raw.IndexOf($endMarker, $si) }

if ($si -lt 0 -or $ei -lt 0) { throw "Nao achei o bloco de privacidade (START/END) em: $target" }

# inclui a linha do END inteira
$endLineIdx = $raw.IndexOf($nl, $ei)
if ($endLineIdx -lt 0) { $endLineIdx = $raw.Length } else { $endLineIdx = $endLineIdx + $nl.Length }
$blockFull = $raw.Substring($si, $endLineIdx - $si)

# remove bloco do arquivo (top-level ou onde estiver)
$raw2 = $raw.Remove($si, $endLineIdx - $si)

# normaliza bloco (sem trocar sem contexto demais; só garante ecoIsOperator(param) depois)
$blockOnly = $blockFull.TrimEnd()

# --- encontrar o handler GET e a abertura do corpo ---
$mode = ""
$paramName = "req"
$insertAt = -1
$baseIndent = ""

# 1) export async function GET(...) {
$m1 = [regex]::Match($raw2, "export\s+(?:async\s+)?function\s+GET\s*\((?<args>[^)]*)\)\s*\{")
if ($m1.Success) {
  $mode = "function"
  $args = $m1.Groups["args"].Value
  $paramName = ParseFirstParamName $args
  $insertAt = $m1.Index + $m1.Length  # logo apos "{"
} else {
  # 2) export const GET = ... (procura o primeiro => depois desse ponto)
  $ix = $raw2.IndexOf("export const GET")
  if ($ix -lt 0) { throw "Nao achei 'export const GET' nem 'export function GET' em $target" }

  $searchEnd = [Math]::Min($raw2.Length, $ix + 4000)
  $segment = $raw2.Substring($ix, $searchEnd - $ix)
  $arrowRel = $segment.IndexOf("=>")
  if ($arrowRel -lt 0) { throw "Nao achei '=>' perto do export const GET (talvez GET nao seja arrow/async?)" }

  $arrowIdx = $ix + $arrowRel
  $mode = "arrow"

  # achar o ')' imediatamente antes do =>
  $j = $arrowIdx - 1
  while ($j -ge 0 -and $raw2[$j] -ne ')') { $j-- }
  if ($j -lt 0) { throw "Nao achei ')' antes do '=>' do GET" }

  # voltar ate o '(' correspondente
  $depth = 0
  $k = $j
  while ($k -ge 0) {
    $ch = $raw2[$k]
    if ($ch -eq ')') { $depth++ }
    elseif ($ch -eq '(') {
      $depth--
      if ($depth -eq 0) { break }
    }
    $k--
  }
  if ($k -lt 0) { throw "Nao consegui casar '(' do argumento do GET" }

  $args = $raw2.Substring($k + 1, $j - $k - 1)
  $paramName = ParseFirstParamName $args

  # depois do =>, pular espacos
  $p = $arrowIdx + 2
  while ($p -lt $raw2.Length -and [char]::IsWhiteSpace($raw2[$p])) { $p++ }

  if ($p -ge $raw2.Length) { throw "Arquivo terminou apos '=>'" }

  if ($raw2[$p] -eq '{') {
    $insertAt = $p + 1 # dentro do bloco
  } else {
    # expression-bodied arrow: transforma em block-bodied
    # captura expr ate delimitador de alto nivel (')' , ',' ou ';')
    $exprStart = $p
    $dp = 0; $db = 0; $dc = 0
    $q = $exprStart
    while ($q -lt $raw2.Length) {
      $ch = $raw2[$q]
      if ($ch -eq '(') { $dp++ }
      elseif ($ch -eq ')') { if ($dp -eq 0 -and $db -eq 0 -and $dc -eq 0) { break } else { $dp-- } }
      elseif ($ch -eq '[') { $db++ }
      elseif ($ch -eq ']') { $db-- }
      elseif ($ch -eq '{') { $dc++ }
      elseif ($ch -eq '}') { $dc-- }
      elseif (($ch -eq ';' -or $ch -eq ',' ) -and $dp -eq 0 -and $db -eq 0 -and $dc -eq 0) { break }
      $q++
    }
    if ($q -ge $raw2.Length) { throw "Nao consegui determinar o fim da expressao do GET" }

    $expr = $raw2.Substring($exprStart, $q - $exprStart).Trim()
    $delim = $raw2[$q]

    # indent base: indent da linha do =>
    $lineStart = $raw2.LastIndexOf($nl, [Math]::Max(0, $arrowIdx - 1))
    if ($lineStart -lt 0) { $lineStart = 0 } else { $lineStart = $lineStart + $nl.Length }
    $prefix = $raw2.Substring($lineStart, [Math]::Min($raw2.Length - $lineStart, 2000))
    if ($prefix -match "^([ \t]*)") { $baseIndent = $Matches[1] } else { $baseIndent = "" }
    $insideIndent = $baseIndent + "  "

    # ajusta ecoIsOperator(param) no bloco
    $blockAdj = [regex]::Replace($blockOnly, "ecoIsOperator\(\s*\w+\s*\)", ("ecoIsOperator(" + $paramName + ")"))

    $blockIndented = IndentBlock $blockAdj $insideIndent $nl

    $replacement =
      "{" + $nl +
      $blockIndented + $nl +
      $insideIndent + "return " + $expr + ";" + $nl +
      $baseIndent + "}"

    # reescreve somente a parte expr
    $raw2 = $raw2.Substring(0, $exprStart) + $replacement + $raw2.Substring($q)  # inclui delim original
    if ($delim -eq ')') {
      # ok
    }
    # agora o GET virou block-bodied, e insertAt nao precisa (ja inserimos o bloco)
    $insertAt = -2
  }
}

# se ainda precisamos inserir (caso com '{' direto)
if ($insertAt -ge 0) {
  # indent base: indent da linha do "{"
  $lineStart = $raw2.LastIndexOf($nl, [Math]::Max(0, $insertAt - 1))
  if ($lineStart -lt 0) { $lineStart = 0 } else { $lineStart = $lineStart + $nl.Length }
  $prefix = $raw2.Substring($lineStart, [Math]::Min($raw2.Length - $lineStart, 2000))
  if ($prefix -match "^([ \t]*)") { $baseIndent = $Matches[1] } else { $baseIndent = "" }
  $insideIndent = $baseIndent + "  "

  $blockAdj = [regex]::Replace($blockOnly, "ecoIsOperator\(\s*\w+\s*\)", ("ecoIsOperator(" + $paramName + ")"))
  $blockIndented = IndentBlock $blockAdj $insideIndent $nl

  $inject = $nl + $blockIndented + $nl
  $raw2 = $raw2.Insert($insertAt, $inject)
}

# backup + write
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-173\" + $stamp)
$bak = BackupFile $target $backupDir
WriteUtf8NoBom $target $raw2

# report
EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-173-fix-pickuprequests-privacy-block-into-get-" + $stamp + ".md")

$r = @()
$r += "# eco-step-173 — fix pickup-requests privacy block into GET — $stamp"
$r += ""
$r += "## DIAG"
$r += "- alvo: src/app/api/pickup-requests/route.ts"
$r += "- bloco encontrado: sim (START/END)"
$r += "- modo GET detectado: " + $mode
$r += "- param detectado: " + $paramName
$r += "- backup: " + $bak
$r += ""
$r += "## PATCH"
$r += "- removeu o bloco do top-level e reinseriu dentro do handler GET (no inicio do corpo)."
$r += ""
$r += "## VERIFY"
$r += "Rode:"
$r += "- npm run build"
$r += "- (se existir) pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport"
$r += ""
WriteUtf8NoBom $reportPath ($r -join $nl)

Write-Host ("[OK] patched: " + $target)
Write-Host ("[REPORT] " + $reportPath)

if ($OpenReport) { try { Start-Process $reportPath | Out-Null } catch {} }