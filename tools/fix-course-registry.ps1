$ErrorActionPreference = "Stop"

function WriteUtf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path -Parent $path
  if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

$courseRoot = "app/formacao/cursos"
if (!(Test-Path $courseRoot)) { throw "Nao achei $courseRoot. Rode na raiz do repo." }

$dirs = Get-ChildItem -Path $courseRoot -Directory | Where-Object { $_.Name -ne "[slug]" -and $_.Name -notmatch '^\.' }

$courses = @()
foreach ($d in $dirs) {
  $slug = $d.Name
  $dataTs  = Join-Path $d.FullName "course-data.ts"
  $dataTsx = Join-Path $d.FullName "course-data.tsx"
  $data = $null
  if (Test-Path $dataTs) { $data = $dataTs } elseif (Test-Path $dataTsx) { $data = $dataTsx } else { continue }

  $txt = Get-Content -LiteralPath $data -Raw
  $names = @([regex]::Matches($txt, 'export\s+const\s+([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value })
  $pack = ($names | Where-Object { $_ -match '^course' -and $_ -ne 'courseMeta' } | Select-Object -First 1)
  if (-not $pack) { $pack = ($names | Select-Object -First 1) }
  if ($pack) { $courses += [pscustomobject]@{ slug=$slug; pack=$pack } }
}

if ($courses.Count -eq 0) { throw "Nao consegui detectar nenhum pack em course-data.ts/tsx." }

$imports = ($courses | ForEach-Object { 'import { ' + $_.pack + ' } from "./' + $_.slug + '/course-data";' }) -join "`n"
$items   = ($courses | ForEach-Object { '  { slug: "' + $_.slug + '", pack: ' + $_.pack + ' as any },' }) -join "`n"
$cases   = ($courses | ForEach-Object { '    case "' + $_.slug + '": return ' + $_.pack + ' as any;' }) -join "`n"

$registry = @"
$imports

export const COURSES: { slug: string; pack: any }[] = [
$items
];

export function getCoursePack(slug: string): any {
  switch (slug) {
$cases
    default: return null;
  }
}
"@

WriteUtf8NoBom "app/formacao/cursos/course-registry.ts" $registry
Write-Host "OK: app/formacao/cursos/course-registry.ts (re)criado com $($courses.Count) cursos" -ForegroundColor Green

Write-Host "`nAgora rode:" -ForegroundColor Cyan
Write-Host "  npm run build" -ForegroundColor Yellow