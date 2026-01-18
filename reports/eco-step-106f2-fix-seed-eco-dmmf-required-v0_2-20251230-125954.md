# eco-step-106f2-fix-seed-eco-dmmf-required-v0_2

- Time: 20251230-125954
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-125954-eco-step-106f2-fix-seed-eco-dmmf-required-v0_2
- Patched: src/app/api/dev/seed-eco/route.ts

## What/Why
- Seed estava quebrando por campos obrigatórios sem valor (ex.: kind/actor) e/ou valores inválidos (actor: String).
- Agora usa Prisma.dmmf para preencher qualquer scalar/enum required sem default com valores seguros, sem PRAGMA.

## Verify
1) Ctrl+C -> npm run dev
2) irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1&replicar=1' -SkipHttpErrorCheck | ConvertTo-Json -Depth 80
3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 100
4) abrir /eco/mural e /eco/mural/confirmados