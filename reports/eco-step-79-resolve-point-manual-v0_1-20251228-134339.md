# eco-step-79-resolve-point-manual-v0_1

- Time: 
20251228-134339
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-134339-eco-step-79-resolve-point-manual-v0_1
- Base: eco/
pontos

## Added
- src/app/api/eco/points/get/route.ts
- src/app/api/eco/points/resolve/route.ts
- src/app/eco/
pontos
/[id]/resolver/page.tsx
- src/app/eco/
pontos
/[id]/resolver/PointResolveClient.tsx

## Behavior
- POST /api/eco/points/resolve marca RESOLVED + salva proofUrl/proofNote em meta (e top-level se existir).

## Verify
1) Ctrl+C -> npm run dev
2) Abrir um ponto: /eco/
pontos
/<ID>
3) Clicar "Resolver ponto (prova)" (ou abrir /eco/
pontos
/<ID>/resolver)
4) Enviar foto e/ou nota -> "Marcar como RESOLVIDO"
5) Voltar ao ponto e ver: status/Prova/Nota (no bloco que já criamos no Passo 77)