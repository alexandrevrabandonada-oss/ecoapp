# eco-step-80-share-point-card-v0_1

- Time: 
20251228-135921
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-135921-eco-step-80-share-point-card-v0_1
- Base: eco/
pontos

## Added
- src/app/api/eco/points/card/route.tsx
- src/app/eco/share/ponto/[id]/page.tsx
- src/app/eco/share/ponto/[id]/SharePointClient.tsx

## Verify
1) Ctrl+C -> npm run dev
2) Abra /eco/share/ponto/<ID>
3) Verifique o card 3:4 (sem erro de display flex) e 1:1
4) Copiar legenda/link e abrir WhatsApp
5) (Opcional) abrir /api/eco/points/card?format=3x4&id=<ID> direto