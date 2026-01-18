param([string]$Root = (Get-Location).Path)

$ErrorActionPreference = "Stop"
$me = "eco-step-121f-fix-bootstrap-and-readable-mural-v0_2"
$stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

# helpers locais (não dependem do bootstrap)
function EnsureDirLocal([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  if (!(Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBomLocal([string]$p, [string]$content) {
  $enc = New-Object System.Text.UTF8Encoding($false)
  EnsureDirLocal (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $content, $enc)
}
function BackupFileLocal([string]$p, [string]$dir) {
  if (!(Test-Path -LiteralPath $p)) { return }
  EnsureDirLocal $dir
  $leaf = [IO.Path]::GetFileName($p)
  Copy-Item -LiteralPath $p -Destination (Join-Path $dir ($leaf + ".bak")) -Force
}

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDirLocal $backupDir

# (1) FIX tools/_bootstrap.ps1
$bootPath = Join-Path $Root "tools\_bootstrap.ps1"
if (Test-Path -LiteralPath $bootPath) { BackupFileLocal $bootPath $backupDir }

$bootLines = @(
"# tools/_bootstrap.ps1 (safe)",
"Set-StrictMode -Version Latest",
'$ErrorActionPreference = ''Stop''',
"",
"function EnsureDir([string]`$p) {",
"  if ([string]::IsNullOrWhiteSpace(`$p)) { return }",
"  if (!(Test-Path -LiteralPath `$p)) { New-Item -ItemType Directory -Force -Path `$p | Out-Null }",
"}",
"",
"function WriteUtf8NoBom([string]`$path, [string]`$content) {",
"  `$enc = New-Object System.Text.UTF8Encoding(`$false)",
"  EnsureDir (Split-Path -Parent `$path)",
"  [IO.File]::WriteAllText(`$path, `$content, `$enc)",
"}",
"",
"function BackupFile([string]`$path, [string]`$backupDir) {",
"  if (!(Test-Path -LiteralPath `$path)) { return }",
"  EnsureDir `$backupDir",
"  `$leaf = [IO.Path]::GetFileName(`$path)",
"  `$dst = Join-Path `$backupDir (`$leaf + ''.bak'')",
"  Copy-Item -LiteralPath `$path -Destination `$dst -Force",
"}",
"",
"function NewReport([string]`$Root, [string]`$me, [string]`$stamp, [string[]]`$lines) {",
"  `$reports = Join-Path `$Root 'reports'",
"  EnsureDir `$reports",
"  `$path = Join-Path `$reports (`$me + '-' + `$stamp + '.md')",
"  WriteUtf8NoBom `$path (`$lines -join ""`n"")",
"  return `$path",
"}"
)
WriteUtf8NoBomLocal $bootPath ($bootLines -join "`n")
Write-Host ("[PATCH] fixed -> " + $bootPath)

. $bootPath
if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) { throw "[STOP] bootstrap ainda não carregou EnsureDir" }

# (2) FIX MuralReadableStyles.tsx (sem crase/backtick, só concatenação)
$rsPath = Join-Path $Root "src\app\eco\mural\_components\MuralReadableStyles.tsx"
EnsureDir (Split-Path -Parent $rsPath)
if (Test-Path -LiteralPath $rsPath) { BackupFile $rsPath $backupDir }

$rs = @(
"'use client';",
"",
"const css =",
"  '/* MODO LEGIVEL (alto contraste) — escopo: .eco-mural */\n' +",
"  '.eco-mural { background: #f6f6f6 !important; color: #111 !important; min-height: 100vh !important; }\n' +",
"  '.eco-mural * { color: #111 !important; }\n' +",
"  '.eco-mural a { color: #111 !important; text-decoration: none !important; }\n' +",
"  '.eco-mural h1, .eco-mural h2, .eco-mural h3 { color: #111 !important; }\n' +",
"  '.eco-mural button { font-size: 14px !important; font-weight: 900 !important; border: 2px solid #111 !important; border-radius: 12px !important; background: #fff !important; color: #111 !important; padding: 10px 12px !important; }\n' +",
"  '.eco-mural input, .eco-mural select, .eco-mural textarea { background: #fff !important; color: #111 !important; border: 2px solid #111 !important; border-radius: 12px !important; padding: 10px !important; font-size: 14px !important; }\n' +",
"  '.eco-mural main { background: transparent !important; }\n';",
"",
"export default function MuralReadableStyles() {",
"  return <style dangerouslySetInnerHTML={{ __html: css }} />;",
"}",
""
)
WriteUtf8NoBom $rsPath ($rs -join "`n")
Write-Host ("[PATCH] fixed -> " + $rsPath)

# (3) PATCH /eco/mural page: className eco-mural + inserir <MuralReadableStyles />
$muralPage = Join-Path $Root "src\app\eco\mural\page.tsx"
if (Test-Path -LiteralPath $muralPage) {
  $raw = Get-Content -LiteralPath $muralPage -Raw
  if ($raw) {
    $changed = $false

    if ($raw -notmatch 'MuralReadableStyles') {
      BackupFile $muralPage $backupDir

      # inserir import perto dos imports
      $lines = [regex]::Split($raw, "\r?\n")
      $importLine = 'import MuralReadableStyles from "./_components/MuralReadableStyles";'
      $lastImport = -1
      for ($i=0; $i -lt $lines.Length; $i++) {
        if ($lines[$i].StartsWith("import ")) { $lastImport = $i }
      }
      if ($lastImport -ge 0) {
        $pre = $lines[0..$lastImport]
        $post = $lines[($lastImport+1)..($lines.Length-1)]
        $lines = $pre + @($importLine) + $post
      } else {
        $lines = @($importLine) + $lines
      }
      $raw = ($lines -join "`n")
      $changed = $true
    }

    if ($raw.Contains("<main style={{") -and (-not $raw.Contains('className="eco-mural"'))) {
      $raw2 = $raw.Replace("<main style={{", '<main className="eco-mural" style={{')
      if ($raw2 -ne $raw) { $raw = $raw2; $changed = $true }
    }

    if (($raw -notmatch "<MuralReadableStyles") -and $raw.Contains("<h1")) {
      $pos = $raw.IndexOf("<h1")
      if ($pos -ge 0) {
        $raw = $raw.Insert($pos, "      <MuralReadableStyles />`n      ")
        $changed = $true
      }
    }

    if ($changed) {
      WriteUtf8NoBom $muralPage $raw
      Write-Host ("[PATCH] mural readable -> " + $muralPage)
    } else {
      Write-Host "[DIAG] mural page: nada a mudar"
    }
  }
} else {
  Write-Host "[WARN] mural page.tsx não encontrado, pulei patch"
}

# REPORT simples
$r = @()
$r += "# $me"
$r += ""
$r += "- Time: $stamp"
$r += "- Backup: $backupDir"
$r += ""
$r += "## Patched"
$r += "- tools/_bootstrap.ps1 (fix)"
$r += "- src/app/eco/mural/_components/MuralReadableStyles.tsx (fix, sem template string)"
$r += "- src/app/eco/mural/page.tsx (eco-mural + style inject)"
$r += ""
$r += "## Verify"
$r += "1) Ctrl+C -> npm run dev"
$r += "2) abrir /eco/mural (tem que ficar legível)"
$reportPath = NewReport $Root $me $stamp $r
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"