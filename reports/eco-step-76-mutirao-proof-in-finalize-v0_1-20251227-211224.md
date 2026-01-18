# eco-step-76-mutirao-proof-in-finalize-v0_1

- Time: 
20251227-211224
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-211224-eco-step-76-mutirao-proof-in-finalize-v0_1

## Added
- src/app/api/eco/mutirao/proof/route.ts (POST)

## Patched
- 
src\app\eco\mutiroes\[id]\finalizar\MutiraoFinishClient.tsx

## O que mudou
- Tela finalizar agora: nota + upload (ou URL) -> salva prova (best-effort) -> finaliza -> botão Abrir Share

## Verify
1) Ctrl+C -> npm run dev
2) Abrir /eco/mutiroes/<id>/finalizar
3) Escrever nota, enviar foto (ou colar URL), clicar Finalizar
4) Abrir Share e conferir card mostrando PROVA/DEPOIS