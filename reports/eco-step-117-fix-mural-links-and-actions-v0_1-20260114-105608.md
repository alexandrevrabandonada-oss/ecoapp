# eco-step-117-fix-mural-links-and-actions-v0_1

- Time: 20260114-105608
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-105608-eco-step-117-fix-mural-links-and-actions-v0_1

## Patched
- src/app/api/eco/points/action/route.ts (rewrite DMMF-safe)

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (não pode aparecer hydration error de <a> dentro de <a>)
3) $pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id
4) $b = @{ pointId = $pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress
5) irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body $b | ConvertTo-Json -Depth 60
6) abrir /eco/mural e clicar ✅ 🤝 ♻️ (contadores sobem)
