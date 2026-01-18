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

function InsertAfterMainOpen([string]$txt, [string]$insert){
  $idxMain = $txt.IndexOf("<main")
  if($idxMain -ge 0){
    $idxGt = $txt.IndexOf(">", $idxMain)
    if($idxGt -ge 0){
      return $txt.Insert($idxGt + 1, "`n" + $insert + "`n")
    }
  }
  # fallback: insert right after first "return ("
  $m = [regex]::Match($txt, "return\s*\(\s*", "IgnoreCase")
  if($m.Success){
    return $txt.Insert($m.Index + $m.Length, "`n" + $insert + "`n")
  }
  # fallback2: prepend
  return $insert + "`n" + $txt
}

$rep = NewReport "eco-step-23b-pedidos-add-operator-shortcut"
$log = @()
$log += "# ECO — STEP 23b — Atalho /operador dentro de /pedidos"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# localizar /pedidos page
$pedidos = "src/app/pedidos/page.tsx"
if(!(Test-Path -LiteralPath $pedidos)){
  $pedidos = FindFirst "." "\\src\\app\\pedidos\\page\.tsx$"
}
if(!(Test-Path -LiteralPath $pedidos)){
  $log += "## DIAG"
  $log += "- ERRO: não encontrei src/app/pedidos/page.tsx"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei /pedidos (src/app/pedidos/page.tsx)."
}

$txt = Get-Content -LiteralPath $pedidos -Raw

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $pedidos)
$log += ("Já tem /operador? {0}" -f (($txt -match "href\s*=\s*['""]/operador['""]") ? "SIM" : "NÃO"))
$log += ""

$log += "## PATCH"
$log += ("Backup: {0}" -f (BackupFile $pedidos))

if($txt -match "href\s*=\s*['""]/operador['""]"){
  $log += "- INFO: já existe link para /operador (skip)."
} else {
  $block = @"
<div className="mb-3 flex flex-wrap items-center gap-3 rounded-xl border px-3 py-2 text-sm">
  <a className="underline" href="/operador">Modo Operador</a>
  <span className="opacity-70">Salvar/limpar token e voltar pros pedidos.</span>
</div>
"@

  $before = $txt
  $txt = InsertAfterMainOpen $txt $block
  if($txt -ne $before){
    $log += "- OK: atalho inserido."
  } else {
    $log += "- WARN: não consegui inserir (texto ficou igual)."
  }

  WriteUtf8NoBom $pedidos $txt
}

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /pedidos -> deve aparecer link 'Modo Operador'"
$log += "4) Clique e confirme /operador funcionando"
$log += ""
$log += "## COMMIT (recomendado)"
$log += "git status"
$log += "git add -A"
$log += "git commit -m `"eco: atalhos operador em /pedidos`""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 23b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /pedidos e confira o atalho 'Modo Operador'" -ForegroundColor Yellow