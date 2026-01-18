# eco-step-101-fix-pointid-crash-supportbutton-v0_1

- Time: 
20251229-134125
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-134125-eco-step-101-fix-pointid-crash-supportbutton-v0_1

## Change
- Rewrote src/app/eco/_components/PointSupportButton.tsx to never reference pointId as a free identifier.

## Verify
1) npm run dev
2) abrir /eco/mural/confirmados (nao pode dar 500)
3) se aparecer botao 🤝 Apoiar, clicar nao pode crashar