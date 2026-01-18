# eco-step-130-add-mapa-link-in-actions-safe-v0_1

- Time: 20260114-192749
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-192749-eco-step-130-add-mapa-link-in-actions-safe-v0_1
- Patched: src/app/eco/mural/_components/MuralPointActionsClient.tsx (rewrite + 🗺️ link)

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural e ver o botão 🗺️ Mapa nos cards
3) clicar 🗺️ Mapa (abre /eco/mapa?focus=...)
4) testar ação:
   $pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id
   $b = @{ pointId = $pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress
   irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body $b | ConvertTo-Json -Depth 60
