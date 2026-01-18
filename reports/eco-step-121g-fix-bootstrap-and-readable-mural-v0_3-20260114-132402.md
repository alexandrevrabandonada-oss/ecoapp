# eco-step-121g-fix-bootstrap-and-readable-mural-v0_3

- Time: 20260114-132402
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-132402-eco-step-121g-fix-bootstrap-and-readable-mural-v0_3

## Patched
- tools/_bootstrap.ps1 (fix aspas)
- src/app/eco/mural/_components/MuralReadableStyles.tsx (css legível)
- src/app/eco/mural/page.tsx (eco-mural + style inject)

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (deve ficar legível)