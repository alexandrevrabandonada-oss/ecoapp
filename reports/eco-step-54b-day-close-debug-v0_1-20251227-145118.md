# eco-step-54b-day-close-debug-v0_1

- Time: 
20251227-145118
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-145118-eco-step-54b-day-close-debug-v0_1
- Patched:
  - 
C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\day-close\route.ts
  - 
C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\day-close\compute\route.ts

## What changed
- safeDay ficou mais robusto (normaliza hífens unicode, aceita YYYY-MM-DD e prefixo YYYY-MM-DDT...).
- bad_day agora devolve got:{day,d,date} para a gente ver o que chegou de verdade.

