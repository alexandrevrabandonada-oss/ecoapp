# eco-step-58b-fix-hydration-share-links-v0_1

- Time: 
20251227-164752
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-164752-eco-step-58b-fix-hydration-share-links-v0_1

## Fix
- Move window.location.href to useEffect in ShareDayClient/ShareMonthClient to avoid hydration mismatch.

## Verify
- Restart dev server
- Open /eco/share/dia/2025-12-27 and /eco/share/mes/2025-12
- Confirm no hydration warning and WhatsApp button works

