# eco-step-103-fix-pointactionsinline-pointid-scope-v0_1

- Time: 
20251229-140405
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-140405-eco-step-103-fix-pointactionsinline-pointid-scope-v0_1

## What
- Rewrote src/app/eco/_components/PointActionsInline.tsx to avoid bare pointId ReferenceError.
- Now derives id from props.pointId OR props.point/data/item/id and calls APIs directly.

## Verify
1) Ctrl+C -> npm run dev
2) Open /eco/mural/confirmados (must not crash with pointId is not defined)
3) Click ✅/🤝/♻️ and confirm POSTs to /api/eco/points/(confirm|support|replicar) work
