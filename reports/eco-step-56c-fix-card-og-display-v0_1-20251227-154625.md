# eco-step-56c-fix-card-og-display-v0_1

- Time: 
20251227-154625
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-154625-eco-step-56c-fix-card-og-display-v0_1

## Fix
- next/og: garante display:flex em todos os <div> para evitar erro 'Expected <div> to have explicit display...'

## Verify
- Reinicie dev server e abra:
  - http://localhost:3000/api/eco/day-close/card?day=2025-12-27&format=3x4
  - http://localhost:3000/api/eco/day-close/card?day=2025-12-27&format=1x1

