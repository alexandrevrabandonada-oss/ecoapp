# eco-fix-day-close-parse-v0_1

- Time: 
20251227-144605
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-144605-eco-fix-day-close-parse-v0_1
- Patched: 
  - 
C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\day-close\route.ts
  - 
C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\day-close\compute\route.ts

## Notes
- Reescreveu os dois routes multilinha pra eliminar parse error do Turbopack.
- safeDay agora aceita YYYY-MM-DD com regex literal correta (/^\\d.../).
- Query aceita day|d|date.
