# eco-step-114-fix-mural-links-inject-actions-v0_1

- Time: 20260114-101828
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-101828-eco-step-114-fix-mural-links-inject-actions-v0_1

## Patched
- src/app/eco/mural/page.tsx (fix nested <a>)
- src/app/eco/mural/MuralClient.tsx (inject actions)
- src/app/eco/mural-acoes/MuralAcoesClient.tsx (inject actions)
- scan: '/api/eco/points2' -> '/api/eco/points' (1 files)

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (sem hydration error)
3) clicar ✅ 🤝 ♻️ (contadores sobem sem refresh)
4) testar API:
   $pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id
   $b = @{ pointId = $pid; action = 'confirm' } | ConvertTo-Json -Compress
   irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body $b | ConvertTo-Json -Depth 60
