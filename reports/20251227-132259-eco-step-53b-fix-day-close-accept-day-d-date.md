# ECO — STEP 53B — Fix day-close aceitar day/d/date

Data: 2025-12-27 13:22:59
PWD : C:\Projetos\App ECO\eluta-servicos

## Backup
- tools/_patch_backup/20251227-132259-src_app_api_eco_day-close_route.ts

## PATCH
- OK: normalizei const day para aceitar day/d/date.

## DIAG (trechos com day)
  const day = safeDay(searchParams.get("day") ?? searchParams.get("d") ?? searchParams.get("date"));
  const fresh = String(searchParams.get("fresh") || "").trim() === "1";
  const day = safeDay(body?.day ?? null);
