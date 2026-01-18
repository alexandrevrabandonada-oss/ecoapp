# eco-step-64-mutirao-upload-before-after-v0_2

- Time: 
20251227-173500
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-173500-eco-step-64-mutirao-upload-before-after-v0_2

## Added
- POST /api/eco/upload (multipart -> public/eco-uploads)

## Patched
- /eco/mutiroes/[id] upload antes/depois
- /api/eco/mutirao/card renderiza imagens

## Verify
1) restart dev
2) abrir /eco/mutiroes/[id], subir fotos, salvar
3) abrir /api/eco/mutirao/card?format=3x4&id=...
