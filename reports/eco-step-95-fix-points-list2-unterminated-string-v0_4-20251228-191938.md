# eco-step-95-fix-points-list2-unterminated-string-v0_4

- Time: 20251228-191938
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-191938-eco-step-95-fix-points-list2-unterminated-string-v0_4
- File: C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\list2\route.ts

## Patch
- Corrige bracket access com string multiline em TS:
- pc?.["<newline>ecoPointConfirm<newline>"] -> pc?.["ecoPointConfirm"]
- pc?.['<newline>ecoPointConfirm<newline>'] -> pc?.["ecoPointConfirm"]

## Verify
1) Ctrl+C
2) npm run dev
3) http://localhost:3000/api/eco/points/list2?limit=10 (200)

## Notes
- changed=True
- stillBad=False