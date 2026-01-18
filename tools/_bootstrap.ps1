Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p,[string]$content){ [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false)) }
function ReadRaw([string]$p){ return [IO.File]::ReadAllText($p, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$root,[string]$stamp,[string]$file,[ref]$r){
  if(!(Test-Path -LiteralPath $file)){ $r.Value += ("- skip backup (nao existe): " + $file); return }
  $bkDir = Join-Path $root "tools/_patch_backup"; EnsureDir $bkDir
  $name = [IO.Path]::GetFileName($file)
  $dest = Join-Path $bkDir ($name + ".bak-" + $stamp)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  $r.Value += ("- backup: " + $dest)
}
function FindNpmCmd(){ $c = Get-Command npm.cmd -ErrorAction SilentlyContinue; if($c){ return $c.Source }; return "npm.cmd" }
function RunNpm([string[]]$args){ $npm = FindNpmCmd; return (& $npm @args 2>&1 | Out-String) }