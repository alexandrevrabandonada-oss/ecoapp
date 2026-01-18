# eco-step-113h-add-point-actions-optimistic-safe-v0_1

- Time: 20260103-184128
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260103-184128-eco-step-113h-add-point-actions-optimistic-safe-v0_1

## What/Why
- Criado POST /api/eco/points/action (confirm/support/replicar) robusto com Prisma.dmmf.
- Criado componente client com UI otimista + rollback.
- Tentativa de injetar o componente no MuralClient/MuralAcoesClient.

## Patched
- src/app/api/eco/points/action/route.ts
- src/app/eco/mural/_components/MuralPointActionsClient.tsx
- Front injected: (nenhum) — se aparecer WARN, a gente injeta manualmente no arquivo certo.

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural e clicar ✅ 🤝 ♻️ (contadores devem subir)
3) teste API:
   $b = @{ pointId = "PONHA_UM_ID"; action = "confirm" } | ConvertTo-Json -Compress
   irm "http://localhost:3000/api/eco/points/action" -Method Post -ContentType "application/json" -Body $b | ConvertTo-Json -Depth 60
