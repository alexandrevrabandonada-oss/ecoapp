# eco-step-107g-fix-points-list-alias-and-front-safe-v0_1

- Time: 20251230-163513
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-163513-eco-step-107g-fix-points-list-alias-and-front-safe-v0_1

## What/Why
- /api/eco/points/list estava quebrado (model_not_ready -> 503).
- Agora /list é ALIAS de /list2 (fonte única).
- E o front foi varrido pra trocar chamadas antigas de /list por /api/eco/points (compat).

## Patched
- src/app/api/eco/points/list/route.ts (alias para list2)
- Front files updated:
  - C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\MuralClient.tsx
  - C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\_components\MuralTopBar.tsx
  - C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\_components\MuralTopBarClient.tsx
  - C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural-acoes\MuralAcoesClient.tsx

## Verify
1) Ctrl+C -> npm run dev
2) irm 'http://localhost:3000/api/eco/points/list?limit=20' | ConvertTo-Json -Depth 40
3) abrir /eco/mural e /eco/mural/confirmados (não pode aparecer 503 do list)
