# eco-step-63-mutirao-finish-share-card-v0_1

- Time: 
20251227-172126
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-172126-eco-step-63-mutirao-finish-share-card-v0_1

## Added
- API: GET  /api/eco/mutirao/get?id=...
- API: POST /api/eco/mutirao/update (rascunho: beforeUrl/afterUrl/checklist)
- API: POST /api/eco/mutirao/finish  (DONE)
- API: GET  /api/eco/mutirao/card?format=3x4&id=... (+ 1x1)
- UI: /eco/mutiroes/[id] (detalhe)
- UI: /eco/share/mutirao/[id] (share)
- UI: /eco/mutiroes (botões Abrir/Compartilhar)

## Verify
1) Restart dev server
2) Abra /eco/mutiroes, clique em Abrir
3) Preencha before/after URLs, marque checklist, salve rascunho
4) Finalize (DONE)
5) Abra /eco/share/mutirao/[id] e clique em Abrir card 3:4
6) Teste APIs: /api/eco/mutirao/get?id=... e /api/eco/mutirao/card?format=3x4&id=...

