param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$text){ [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file, [string]$bakRoot){
  if(!(Test-Path -LiteralPath $file)){ return $null }
  EnsureDir $bakRoot
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakRoot ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$targetRel = "src\app\api\pickup-requests\route.ts"
$target = Join-Path $repoRoot $targetRel
if(!(Test-Path -LiteralPath $target)){ throw ("missing: " + $targetRel) }

$raw = Get-Content -LiteralPath $target -Raw
$nl = "`r`n"; if($raw -notmatch "`r`n"){ $nl = "`n" }

$startMarker = "// ECO_PICKUP_RECEIPT_PRIVACY_START"
$endMarker   = "// ECO_PICKUP_RECEIPT_PRIVACY_END"

$si = $raw.IndexOf($startMarker)
if($si -lt 0){ throw "Nao achei START marker no route.ts" }
$ei = $raw.IndexOf($endMarker, $si)
if($ei -lt 0){ throw "Nao achei END marker no route.ts" }
# pega ate o fim da linha do END
$endLine = $raw.IndexOf($nl, $ei)
if($endLine -lt 0){ $endCut = $raw.Length } else { $endCut = $endLine + $nl.Length }
$block = $raw.Substring($si, $endCut - $si)
$raw2  = $raw.Remove($si, $endCut - $si)

# localizar o handler GET e achar uma declaracao de items depois dele
$mGet = [regex]::Match($raw2, "export\s+async\s+function\s+GET\s*\(", [System.Text.RegularExpressions.RegexOptions]::Singleline)
if(!$mGet.Success){ throw "Nao achei export async function GET(" }
$braceIx = $raw2.IndexOf("{", $mGet.Index)
if($braceIx -lt 0){ throw "Nao achei { do GET" }
$bodyStart = $braceIx + 1

$after = $raw2.Substring($bodyStart)

# procura primeiro lugar onde items é declarado (const/let/var items OU destructuring com { items } OU items = ...)
$rx1 = [regex]::new("(?m)^[ \t]*(const|let|var)\s+items\b", [System.Text.RegularExpressions.RegexOptions]::Singleline)
$rx2 = [regex]::new("(?m)^[ \t]*(const|let|var)\s*\{[^\}]*\bitems\b[^\}]*\}\s*=", [System.Text.RegularExpressions.RegexOptions]::Singleline)
$rx3 = [regex]::new("(?m)^[ \t]*items\s*=", [System.Text.RegularExpressions.RegexOptions]::Singleline)

$cand = @()
$m1 = $rx1.Match($after); if($m1.Success){ $cand += $m1 }
$m2 = $rx2.Match($after); if($m2.Success){ $cand += $m2 }
$m3 = $rx3.Match($after); if($m3.Success){ $cand += $m3 }
if($cand.Count -eq 0){ throw "Nao encontrei declaracao/atribuicao de items dentro do GET. Vou precisar do trecho do arquivo." }
$best = $cand | Sort-Object Index | Select-Object -First 1

$declAbs = $bodyStart + $best.Index
# acha o fim do statement (primeiro ; depois da declaracao)
$semi = $raw2.IndexOf(";", $declAbs)
if($semi -lt 0){ throw "Nao achei ; depois da declaracao de items (statement sem ;?)" }
$insertAt = $semi + 1

# indent: usa o indent da linha da declaracao + 2 espaços
$lineStart = $raw2.LastIndexOf($nl, [Math]::Max(0, $declAbs - 1))
if($lineStart -lt 0){ $lineStart = 0 } else { $lineStart = $lineStart + $nl.Length }
$linePrefix = $raw2.Substring($lineStart, [Math]::Min($raw2.Length - $lineStart, 2000))
$baseIndent = ""
if($linePrefix -match "^([ \t]*)"){ $baseIndent = $Matches[1] }
$insideIndent = $baseIndent + "  "

# ajusta ecoIsOperator(x) -> ecoIsOperator(req) (GET ja tem req: Request)
$blockAdj = [regex]::Replace($block, "ecoIsOperator\(\s*\w+\s*\)", "ecoIsOperator(req)")

# reindenta o bloco (best-effort)
$blockLines = ($blockAdj -split "\r?\n")
$minIndent = 999999
foreach($l in $blockLines){
  if($l -match "^\s*$"){ continue }
  if($l -match "^([ \t]+)"){ $n=$Matches[1].Length; if($n -lt $minIndent){ $minIndent=$n } } else { $minIndent=0; break }
}
if($minIndent -eq 999999){ $minIndent = 0 }
$rebuilt = @()
foreach($l in $blockLines){
  if($l -match "^\s*$"){ $rebuilt += $insideIndent.TrimEnd(); continue }
  $cut = $l; if($minIndent -gt 0 -and $cut.Length -ge $minIndent){ $cut = $cut.Substring($minIndent) }
  $rebuilt += ($insideIndent + $cut)
}
$blockIndented = ($rebuilt -join $nl)

$inject = $nl + $blockIndented + $nl
$newRaw = $raw2.Insert($insertAt, $inject)

# backup + write + report
$stamp = NowStamp
EnsureDir (Join-Path $repoRoot "reports")
EnsureDir (Join-Path $repoRoot "tools\_patch_backup\eco-step-175")
$bak = BackupFile $target (Join-Path $repoRoot "tools\_patch_backup\eco-step-175")
WriteUtf8NoBom $target $newRaw

$reportPath = Join-Path $repoRoot ("reports\eco-step-175-move-pickuprequests-privacy-block-after-items-" + $stamp + ".md")
$r = @()
$r += ("# eco-step-175 — move pickup-requests privacy block after items — " + $stamp)
$r += ""
$r += "## DIAG"
$r += ("- alvo: " + $targetRel)
$r += ("- insertAt apos declaracao items (index abs): " + $insertAt)
$r += ("- backup: " + $bak)
$r += ""
$r += "## VERIFY"
$r += "- npm run build"
$r += ""
WriteUtf8NoBom $reportPath ($r -join $nl)
Write-Host ("[OK] patched: " + $target)
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try{ Start-Process $reportPath | Out-Null } catch{} }
Write-Host ""
Write-Host "[NEXT] rode:"
Write-Host "  npm run build"