# eco-step-128-fix-mural-referror-guards-v0_1

- Time: 20260114-191026
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-191026-eco-step-128-fix-mural-referror-guards-v0_1
- Bootstrap loaded: True

## Changed
- (none)

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (não pode ter ReferenceError p/it/item)
3) abrir /eco/mapa
4) (opcional) testar ação:
   $pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id
   $b = @{ pointId = $pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress
   irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body $b | ConvertTo-Json -Depth 60
