# eco-step-112-add-create-point-and-ui-v0_3

- Time: 20260103-182504
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260103-182504-eco-step-112-add-create-point-and-ui-v0_3

## What/Why
- Garante POST /api/eco/points (criar ponto).
- Adiciona/garante UI de registro no mural.
- Corrige hidratação: remove <a> dentro de <a> no /eco/mural.
- Cria alias /api/eco/points2 -> /api/eco/points (para parar 404).

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (não pode aparecer hydration error de <a>)
3) Teste POST:
   $b = @{ lat=-22.521; lng=-44.105; kind="LIXO_ACUMULADO"; status="OPEN"; note="teste" } | ConvertTo-Json -Compress
   irm "http://localhost:3000/api/eco/points" -Method Post -ContentType "application/json" -Body $b | ConvertTo-Json -Depth 40
4) irm 'http://localhost:3000/api/eco/points2?limit=5' | ConvertTo-Json -Depth 40
