# eco-step-56-day-close-card-v0_1

- Time: 
20251227-153452
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-153452-eco-step-56-day-close-card-v0_1

## Added
- PNG Card: /api/eco/day-close/card?day=YYYY-MM-DD&format=3x4|1x1 (edge ImageResponse)

## Updated
- /eco/fechamento: botões Abrir Card 3:4 e 1:1

## Verify
- Abra:
  - http://localhost:3000/eco/fechamento
- Teste:
  - http://localhost:3000/api/eco/day-close/card?day=2025-12-26&format=3x4
  - http://localhost:3000/api/eco/day-close/card?day=2025-12-26&format=1x1

