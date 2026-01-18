# eco-step-127-fix-p-undefined-openstreetmap-and-sort-auto-v0_1

- Time: 20260114-173544
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-173544-eco-step-127-fix-p-undefined-openstreetmap-and-sort-auto-v0_1

## MuralClient.tsx
- before: p.=6 it.=0 item.=0
- mapVarNearOSM: item
- patched: YES
- after:  p.=2 it.=0 item.=4

## MuralAcoesClient.tsx
- before: p.=4 it.=0 item.=8
- mapVarNearOSM: item
- extraFix: p. remained but no sort((a,b) found; left as-is
- patched: NO (no changes)
- after:  p.=4 it.=0 item.=8
