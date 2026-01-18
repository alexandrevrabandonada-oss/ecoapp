# ECO — STEP 36e — Fix next/og: div com múltiplos filhos exige display:flex

Data: 2025-12-26 14:42:25
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/app/api/share/route-day-card/route.ts
Backup : tools/_patch_backup/20251226-144225-src_app_api_share_route-day-card_route.ts

## PATCH
- OK: adicionou display:flex no pill() (evita erro do next/og).

## VERIFY
1) Sem precisar reiniciar: teste novamente:
   - /api/share/route-day-card?day=2025-12-26&format=3x4
   - /api/share/route-day-card?day=2025-12-26&format=1x1
2) Se ainda der 500, me cola o trecho do pill() do route.ts.