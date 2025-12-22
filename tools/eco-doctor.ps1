. "$PSScriptRoot/_lib.ps1"
$ErrorActionPreference = "Stop"

$rep = New-Report "eco-doctor"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$routes = List-Routes
$models = List-Prisma-Models

$node = (node -v 2>$null)
$npm  = (npm -v 2>$null)

$git = ""
try { $git = (git status -sb 2>$null) } catch { $git = "(git indisponível)" }

$md = @()
$md += "# ECO Doctor"
$md += ""
$md += "- Data: $ts"
$md += "- Node: $node"
$md += "- npm : $npm"
$md += ""
$md += "## Git"
$md += '```'
$md += $git
$md += '```'
$md += ""
$md += "## Rotas (pages)"
$md += '```'
$md += ($routes.pages -join "`n")
$md += '```'
$md += ""
$md += "## Rotas (api)"
$md += '```'
$md += ($routes.apis -join "`n")
$md += '```'
$md += ""
$md += "## Prisma models"
$md += '```'
$md += ($models -join "`n")
$md += '```'
$md += ""
$md += "## Sanity checks"
$md += "- prisma/schema.prisma exists: " + (Test-Path "prisma/schema.prisma")
$md += "- @prisma/client require: `n  node -e `"require('@prisma/client'); console.log('ok')`""
$md += ""

WriteUtf8NoBom $rep ($md -join "`n")
Write-Host "✅ Doctor gerado -> $rep" -ForegroundColor Green