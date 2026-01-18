$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. "$PSScriptRoot/_bootstrap.ps1"

$rep = NewReport "eco-step-50-prisma-eco-day-close"
$log = @()
$log += "# ECO — STEP 50 — Prisma: EcoDayClose (model + migrate + generate)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  $schema = "prisma/schema.prisma"
  if(!(Test-Path -LiteralPath $schema)){ throw "GUARD: não achei prisma/schema.prisma" }

  $bk = BackupFile $schema
  $log += "## DIAG"
  $log += ("Schema : {0}" -f $schema)
  $log += ("Backup : {0}" -f $bk)
  $log += ""

  $raw = Get-Content -LiteralPath $schema -Raw
  if([string]::IsNullOrWhiteSpace($raw)){ throw "GUARD: schema.prisma vazio/ilegível" }

  if($raw -match "model\s+EcoDayClose\s*\{"){
    $log += "## PATCH"
    $log += "- SKIP: model EcoDayClose já existe."
    $log += ""
  } else {
    $modelLines = @(
      "model EcoDayClose {",
      "  day       String   @id",
      "  summary   Json",
      "  createdAt DateTime @default(now())",
      "  updatedAt DateTime @updatedAt",
      "}"
    )
    $block = ($modelLines -join "`n")
    $raw2 = ($raw.TrimEnd() + "`n`n" + $block + "`n")
    WriteUtf8NoBom $schema $raw2

    $log += "## PATCH"
    $log += "- OK: adicionado model EcoDayClose ao schema.prisma."
    $log += ""
  }

  $log += "## PRISMA"
  $log += "- Rodando: npx prisma format"
  & npx prisma format | Out-Host

  $log += "- Rodando: npx prisma migrate dev --name eco_day_close"
  & npx prisma migrate dev --name eco_day_close | Out-Host

  $log += "- Rodando: npx prisma generate"
  & npx prisma generate | Out-Host

  $log += ""
  $log += "## VERIFY"
  $log += "1) npm run dev"
  $log += "2) GET /api/eco/day-close?day=2025-12-26  (esperado 404, NÃO 503)"
  $log += "3) POST /api/eco/day-close { day, summary:{} } (esperado 200 ok:true)"
  $log += ""

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 50 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}
