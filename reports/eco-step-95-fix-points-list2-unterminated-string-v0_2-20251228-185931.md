# eco-step-95-fix-points-list2-unterminated-string-v0_2

- Time: 20251228-185931
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-185931-eco-step-95-fix-points-list2-unterminated-string-v0_2
- File: C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\list2\route.ts

## What happened
- Next/Turbopack falhava com Unterminated string constant em /api/eco/points/list2/route.ts
- A causa era um pickModel(pc, "<string com quebra de linha>") gerado multiline e sem fechar corretamente.

## Patch
- Normaliza chamadas multiline para string simples:
- Ex: pickModel(pc, "<newline> ecoPoint <newline>", [ ... ]) -> pickModel(pc, "ecoPoint", [ ... ])

## Verify
1) Ctrl+C
2) npm run dev
3) GET /api/eco/points/list2?limit=10 (deve 200)
4) /eco/mural/confirmados (deve carregar sem 500)

## Notes
- stillBad=False