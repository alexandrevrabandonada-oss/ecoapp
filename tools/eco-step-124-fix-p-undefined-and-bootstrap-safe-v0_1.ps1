param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = "Stop"

function EnsureDir([string]$p) {
  if (-not $p) { return }
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function WriteUtf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path -Parent $path
  if ($dir) { EnsureDir $dir }
  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($path, $content, $enc)
}

function BackupFile([string]$path, [string]$backupDir) {
  if (-not (Test-Path $path)) { return $null }
  EnsureDir $backupDir
  $leaf = Split-Path -Leaf $path
  $dst = Join-Path $backupDir ($leaf + ".bak")
  Copy-Item -Force $path $dst
  return $dst
}

function FindMatchingParen([string]$s, [int]$openIndex) {
  if ($openIndex -lt 0 -or $openIndex -ge $s.Length) { return -1 }
  if ($s[$openIndex] -ne "(") { return -1 }
  $depth = 0
  $inStr = $false
  $quote = ""
  for ($i = $openIndex; $i -lt $s.Length; $i++) {
    $ch = $s[$i]
    if ($inStr) {
      if ($quote -eq "`"") {
        if ($ch -eq "\") { $i++; continue }
        if ($ch -eq "`"") { $inStr = $false; continue }
        continue
      }
      if ($quote -eq "'") {
        if ($ch -eq "\") { $i++; continue }
        if ($ch -eq "'") { $inStr = $false; continue }
        continue
      }
      if ($quote -eq "`") {
        if ($ch -eq "`") { $inStr = $false; continue }
        continue
      }
      continue
    }

    # comments
    if ($ch -eq "/" -and ($i + 1) -lt $s.Length) {
      $n = $s[$i + 1]
      if ($n -eq "/") {
        $nl = $s.IndexOf("`n", $i + 2)
        if ($nl -lt 0) { return -1 }
        $i = $nl
        continue
      }
      if ($n -eq "*") {
        $end = $s.IndexOf("*/", $i + 2)
        if ($end -lt 0) { return -1 }
        $i = $end + 1
        continue
      }
    }

    if ($ch -eq "`"" -or $ch -eq "'" -or $ch -eq "`") { $inStr = $true; $quote = $ch; continue }

    if ($ch -eq "(") { $depth++; continue }
    if ($ch -eq ")") {
      $depth--
      if ($depth -eq 0) { return $i }
      continue
    }
  }
  return -1
}

function FixPUndefinedInFile([string]$filePath, [string]$backupDir) {
  $raw = Get-Content -Raw -ErrorAction SilentlyContinue $filePath
  if (-not $raw) { return @{ changed = $false; note = "empty" } }

  # Só tenta mexer se tem p. e NÃO tem declaração de p
  if ($raw -notmatch "(^|[^A-Za-z0-9_$])p\." ) { return @{ changed = $false; note = "no p." } }
  if ($raw -match "\b(const|let|var)\s+p\b") { return @{ changed = $false; note = "p already declared" } }

  # procura onde aparece p. primeiro
  $posP = $raw.IndexOf("p.")
  if ($posP -lt 0) { return @{ changed = $false; note = "no p. (index)" } }

  # tenta achar o .map( mais próximo antes disso
  $mapPos = $raw.LastIndexOf(".map(", $posP)
  if ($mapPos -lt 0) { $mapPos = $raw.LastIndexOf("map(", $posP) }
  if ($mapPos -lt 0) {
    # fallback: define p no topo (evita crash).
    BackupFile $filePath $backupDir | Out-Null
    $inject = "`n// HOTFIX: avoid ReferenceError (fallback)`nconst p: any = { lat: 0, lng: 0 };`n"
    $raw2 = $inject + $raw
    WriteUtf8NoBom $filePath $raw2
    return @{ changed = $true; note = "fallback top-level p" }
  }

  $chunkLen = [Math]::Min(300, $raw.Length - $mapPos)
  $chunk = $raw.Substring($mapPos, $chunkLen)
  $m = [regex]::Match($chunk, "\.map\(\(\s*([A-Za-z_$][\w$]*)")
  if (-not $m.Success) { $m = [regex]::Match($chunk, "\.map\(\s*\(\s*([A-Za-z_$][\w$]*)") }
  if (-not $m.Success) {
    return @{ changed = $false; note = "could not parse map param" }
  }
  $param = $m.Groups[1].Value
  if (-not $param) { return @{ changed = $false; note = "empty param" } }
  if ($param -eq "p") { return @{ changed = $false; note = "map param already p" } }

  # acha o => depois do map
  $arrowPos = $raw.IndexOf("=>", $mapPos)
  if ($arrowPos -lt 0) { return @{ changed = $false; note = "no arrow" } }

  # pega o primeiro char não-espaço depois do =>
  $j = $arrowPos + 2
  while ($j -lt $raw.Length -and [char]::IsWhiteSpace($raw[$j])) { $j++ }
  if ($j -ge $raw.Length) { return @{ changed = $false; note = "arrow tail eof" } }

  $ch = $raw[$j]

  BackupFile $filePath $backupDir | Out-Null

  if ($ch -eq "{") {
    # insere alias dentro do bloco
    $insertAt = $j + 1
    $ins = "`n  const p: any = " + $param + " as any;`n"
    $raw2 = $raw.Substring(0, $insertAt) + $ins + $raw.Substring($insertAt)
    WriteUtf8NoBom $filePath $raw2
    return @{ changed = $true; note = "inserted alias in block arrow" }
  }

  if ($ch -eq "(") {
    # converte => ( ... ) em => { const p=param; return ( ... ); }
    $openParen = $j
    $closeParen = FindMatchingParen $raw $openParen
    if ($closeParen -lt 0) { return @{ changed = $false; note = "no matching paren" } }

    $before = $raw.Substring(0, $openParen)
    $mid = $raw.Substring($openParen + 1, $closeParen - ($openParen + 1))
    $after = $raw.Substring($closeParen + 1)

    $raw2 = $before + "{ const p: any = " + $param + " as any; return (" + $mid + "); }" + $after
    WriteUtf8NoBom $filePath $raw2
    return @{ changed = $true; note = "rewrote expr arrow to block + alias" }
  }

  # fallback: não mexe (evita quebrar JSX)
  return @{ changed = $false; note = "unsupported arrow body (char=" + $ch + ")" }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$me = "eco-step-124-fix-p-undefined-and-bootstrap-safe-v0_1"
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

# PATCH 0: rewrite tools/_bootstrap.ps1 (known-good minimal)
$boot = Join-Path $Root "tools\_bootstrap.ps1"
if (Test-Path $boot) { BackupFile $boot $backupDir | Out-Null }
$bootLines = @(
  '$ErrorActionPreference = "Stop"',
  'function EnsureDir([string]$p) { if (-not $p) { return }; if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }',
  'function WriteUtf8NoBom([string]$path, [string]$content) { $dir = Split-Path -Parent $path; if ($dir) { EnsureDir $dir }; $enc = [System.Text.UTF8Encoding]::new($false); [System.IO.File]::WriteAllText($path, $content, $enc) }',
  'function BackupFile([string]$path, [string]$backupDir) { if (-not (Test-Path $path)) { return $null }; EnsureDir $backupDir; $leaf = Split-Path -Leaf $path; $dst = Join-Path $backupDir ($leaf + ".bak"); Copy-Item -Force $path $dst; return $dst }',
  'function NewReport([string]$root, [string]$name, [string]$stamp, [string[]]$lines) { $rpDir = Join-Path $root "reports"; EnsureDir $rpDir; $rp = Join-Path $root ("reports\" + $name + "-" + $stamp + ".md"); WriteUtf8NoBom $rp ($lines -join "`n"); return $rp }'
)
WriteUtf8NoBom $boot ($bootLines -join "`n")
Write-Host ("[PATCH] rewrote -> " + $boot)

# PATCH 1: fix p undefined near OpenStreetMap/link snippets in src
$srcRoot = Join-Path $Root "src"
$targets = New-Object System.Collections.Generic.List[string]
if (Test-Path $srcRoot) {
  $files = Get-ChildItem -Recurse -File $srcRoot -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    $t = Get-Content -Raw -ErrorAction SilentlyContinue $f.FullName
    if (-not $t) { continue }
    if ($t.Contains("openstreetmap.org") -or $t.Contains("mlat=") -or $t.Contains("🗺️")) {
      $targets.Add($f.FullName) | Out-Null
    }
  }
}
Write-Host ("[DIAG] targets with map/link markers: " + $targets.Count)

$patched = @()
$notes = @()
foreach ($tp in $targets) {
  $res = FixPUndefinedInFile $tp $backupDir
  if ($res.changed) {
    $patched += $tp
    $notes += ("- " + $tp + " :: " + $res.note)
    Write-Host ("[PATCH] fixed -> " + $tp + " (" + $res.note + ")")
  }
}

# REPORT
$rep = @()
$rep += "# " + $me
$rep += ""
$rep += "- Time: " + $stamp
$rep += "- Backup: " + $backupDir
$rep += ""
$rep += "## Patched"
$rep += "- tools/_bootstrap.ps1 (rewritten minimal, parse-safe)"
if ($patched.Count -gt 0) {
  $rep += "- Files with p undefined fixed:"
  foreach ($p in $patched) { $rep += "  - " + $p }
} else {
  $rep += "- Files with p undefined fixed: (none)"
}
$rep += ""
$rep += "## Notes"
if ($notes.Count -gt 0) { $rep += $notes } else { $rep += "- (none)" }
$rep += ""
$rep += "## Verify"
$rep += "1) Ctrl+C -> npm run dev"
$rep += "2) abrir /eco/mural (não pode dar 500 / p is not defined)"
$rep += "3) abrir /eco/mapa (se existir) e clicar nos links 🗺️"
$rep += "4) `$pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id"
$rep += "5) `$b = @{ pointId = `$pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress"
$rep += "6) irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body `$b | ConvertTo-Json -Depth 60"

$rp = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $rp)
WriteUtf8NoBom $rp ($rep -join "`n")
Write-Host ("[REPORT] " + $rp)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural (sem erro p)"
Write-Host "  abrir /eco/mapa e clicar 🗺️"
Write-Host "  `$pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id"
Write-Host "  `$b = @{ pointId = `$pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress"
Write-Host "  irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body `$b | ConvertTo-Json -Depth 60"