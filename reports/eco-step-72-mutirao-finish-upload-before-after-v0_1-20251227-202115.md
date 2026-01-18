# eco-step-72-mutirao-finish-upload-before-after-v0_1

- Time: 
20251227-202115
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-202115-eco-step-72-mutirao-finish-upload-before-after-v0_1

## Patched
- src/app/api/eco/mutirao/finish/route.ts (accepts beforeUrl/afterUrl + stores in mutirao/meta; resolves point meta too)
- src/app/eco/mutiroes/[id]/finalizar/MutiraoFinishClient.tsx (uploads before/after via /api/eco/upload)

## Verify
1) Ctrl+C -> npm run dev
2) Abra /eco/mutiroes/<id>/finalizar
3) Faça upload de ANTES e DEPOIS (imagens pequenas primeiro)
4) Preencha nota >= 6 chars e finalize
5) Confirme no ponto vinculado (status RESOLVED e meta com beforeUrl/afterUrl se nao existir campo)

## Notes
- Upload espera /api/eco/upload retornar { ok:true, url|mediaUrl|item.url|item.mediaUrl }
- Se seu upload API usa outro shape, me manda o JSON do retorno que eu ajusto o pickUploadUrl.