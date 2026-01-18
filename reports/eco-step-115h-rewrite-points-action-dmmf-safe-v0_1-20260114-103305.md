# eco-step-115h-rewrite-points-action-dmmf-safe-v0_1

- Time: 20260114-103305
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-103305-eco-step-115h-rewrite-points-action-dmmf-safe-v0_1
- Patched: src/app/api/eco/points/action/route.ts

## Verify
1) Ctrl+C -> npm run dev
2) $pid = (irm "http://localhost:3000/api/eco/points?limit=1").items[0].id
3) $b = @{ pointId = $pid; action = "confirm"; actor = "dev" } | ConvertTo-Json -Compress
4) irm "http://localhost:3000/api/eco/points/action" -Method Post -ContentType "application/json" -Body $b | ConvertTo-Json -Depth 60
5) abrir /eco/mural e clicar ✅ 🤝 ♻️
