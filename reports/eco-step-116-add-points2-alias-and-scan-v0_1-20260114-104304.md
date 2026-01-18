# eco-step-116-add-points2-alias-and-scan-v0_1

- Time: 20260114-104304
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-104304-eco-step-116-add-points2-alias-and-scan-v0_1

## Patched
- src/app/api/eco/points2/route.ts (alias GET -> points)
- src replacements:
  - C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points2\route.ts

## Verify
1) Ctrl+C -> npm run dev
2) irm "http://localhost:3000/api/eco/points2?limit=1" | ConvertTo-Json -Depth 40
3) abrir /eco/mural (não pode aparecer 404 de /points2 no console)
