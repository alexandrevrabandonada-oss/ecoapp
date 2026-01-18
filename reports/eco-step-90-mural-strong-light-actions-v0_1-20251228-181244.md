# eco-step-90-mural-strong-light-actions-v0_1

- Time: 
20251228-181244
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-181244-eco-step-90-mural-strong-light-actions-v0_1

## What
- Criou PointActionsInline (5 acoes: Confirmar + WhatsApp templates).
- Reescreveu MuralClient para: selo forte/leve (RECIBO ECO vs REGISTRO) + Acoes inline.

## Verify
1) Ctrl+C -> npm run dev
2) Abrir /eco/mural
3) Cada card mostra selo (RECIBO ECO ou REGISTRO) + 5 botoes
4) Clicar "Confirmar" incrementa e tenta /api/eco/points/confirm
5) Botoes WhatsApp abrem com texto pronto