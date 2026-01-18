# eco-step-74-mutirao-card-before-after-v0_2

- Time: 
20251227-210250
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-210250-eco-step-74-mutirao-card-before-after-v0_2
- File: src/app/api/eco/mutirao/card/route.tsx

## O que mudou
- Card agora mostra ANTES/DEPOIS lado a lado quando houver ambos
- Continua aceitando format=3x4 ou 1x1

## Verify
1) Ctrl+C -> npm run dev
2) /api/eco/mutirao/card?format=3x4&id=<id> (ver antes/depois)
3) /eco/share/mutirao/<id> (previews OK)