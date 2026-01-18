# eco-step-100e-fix-bare-field-identifiers-v0_1

- Time: 20251229-132212
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-132212-eco-step-100e-fix-bare-field-identifiers-v0_1

## Scanned
- src\app\api\eco\critical\confirm\route.ts
- src\app\api\eco\critical\create\route.ts
- src\app\api\eco\critical\list\route.ts
- src\app\api\eco\day-close\route.ts
- src\app\api\eco\day-close\card\route.tsx
- src\app\api\eco\day-close\compute\route.ts
- src\app\api\eco\day-close\list\route.ts
- src\app\api\eco\month-close\route.ts
- src\app\api\eco\month-close\card\route.tsx
- src\app\api\eco\month-close\list\route.ts
- src\app\api\eco\mural\list\route.ts
- src\app\api\eco\mutirao\card\route.tsx
- src\app\api\eco\mutirao\create\route.ts
- src\app\api\eco\mutirao\finish\route.ts
- src\app\api\eco\mutirao\get\route.ts
- src\app\api\eco\mutirao\list\route.ts
- src\app\api\eco\mutirao\proof\route.ts
- src\app\api\eco\mutirao\update\route.ts
- src\app\api\eco\point\detail\route.ts
- src\app\api\eco\point\reopen\route.ts
- src\app\api\eco\points\route.ts
- src\app\api\eco\points\card\route.tsx
- src\app\api\eco\points\confirm\route.ts
- src\app\api\eco\points\get\route.ts
- src\app\api\eco\points\list\route.ts
- src\app\api\eco\points\list2\route.ts
- src\app\api\eco\points\map\route.ts
- src\app\api\eco\points\react\route.ts
- src\app\api\eco\points\replicar\route.ts
- src\app\api\eco\points\report\route.ts
- src\app\api\eco\points\resolve\route.ts
- src\app\api\eco\points\stats\route.ts
- src\app\api\eco\points\support\route.ts
- src\app\api\eco\recibo\list\route.ts
- src\app\api\eco\upload\route.ts

## Patched
- src\app\api\eco\day-close\route.ts
- src\app\api\eco\day-close\compute\route.ts
- src\app\api\eco\month-close\route.ts
- src\app\api\eco\month-close\card\route.tsx
- src\app\api\eco\mural\list\route.ts
- src\app\api\eco\mutirao\card\route.tsx
- src\app\api\eco\mutirao\finish\route.ts
- src\app\api\eco\mutirao\get\route.ts
- src\app\api\eco\mutirao\proof\route.ts
- src\app\api\eco\mutirao\update\route.ts
- src\app\api\eco\point\detail\route.ts
- src\app\api\eco\point\reopen\route.ts
- src\app\api\eco\points\confirm\route.ts
- src\app\api\eco\points\get\route.ts
- src\app\api\eco\points\list\route.ts
- src\app\api\eco\points\map\route.ts
- src\app\api\eco\points\react\route.ts
- src\app\api\eco\points\replicar\route.ts
- src\app\api\eco\points\report\route.ts
- src\app\api\eco\points\resolve\route.ts
- src\app\api\eco\points\stats\route.ts
- src\app\api\eco\points\support\route.ts
- src\app\api\eco\recibo\list\route.ts

## Verify
1) Ctrl+C -> npm run dev
2) Abrir /eco/mural/confirmados (nao pode dar 500)
3) GET /api/eco/points/list2?limit=10 (200)