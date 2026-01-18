# eco-step-60-fix-share-month-params-unwrap-v0_1

- Time: 
20251227-165855
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-165855-eco-step-60-fix-share-month-params-unwrap-v0_1

## Fix
- Avoid crash at params.month by unwrapping params if it is a Promise (Next 16/Turbopack case).
- Ensures ShareMonthClient exists (minimal, hydration-safe).

## Verify
1) Restart dev server
2) Open /eco/share/mes/2025-12
3) Open card links and WhatsApp link

