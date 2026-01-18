# eco-step-177 — fix api/points fieldNames never[] — 20260116-184304

## DIAG
alvo: src\app\api\points\route.ts
ocorrencias antes: 1

## PATCH
[OK]  trocou found.fieldNames.includes("createdAt") por cast (any) para evitar never[]; backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-177\20260116-184304\20260116-184304-C__Projetos_App_ECO_eluta-servicos_src_app_api_points_route.ts

## POS
ocorrencias depois: 0

## VERIFY
- npm run build
