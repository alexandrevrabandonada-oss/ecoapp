# eco-step-91-mural-chamados-topbar-wa-safe-v0_1

- Time: 
20251228-181718
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-181718-eco-step-91-mural-chamados-topbar-wa-safe-v0_1

## What
- PointActionsInline: WhatsApp safe (sem window no render), mensagens com link relativo/absoluto safe.
- MuralClient: novo prop mode="chamados" (filtra OPEN, ordena por 📣).
- Nova pagina: /eco/mural/chamados.
- Botao no /eco/mural apontando para /eco/mural/chamados.

## Verify
1) Ctrl+C -> npm run dev
2) Abrir /eco/mural e clicar "Ver chamados ativos (OPEN)".
3) /eco/mural/chamados deve listar apenas OPEN e ordenar por 📣.
4) WhatsApp abre ao clicar (Apoiar/Replicar/Chamado/Gratidao).
5) Confirmar aumenta contador (e tenta POST /api/eco/points/confirm).