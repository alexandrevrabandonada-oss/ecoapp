# eco-step-68-lock-resolve-via-mutirao-and-30d-stats-v0_1

- Time: 
20251227-195656
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-195656-eco-step-68-lock-resolve-via-mutirao-and-30d-stats-v0_1
- API: src/app/api/eco/points/stats/route.ts
- Widget: src/app/eco/_components/EcoPoints30dWidget.tsx
- Patched page: 
C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\page.tsx
- Guarded update routes (best-effort): 
0


## Verify
1) Ctrl+C -> npm run dev
2) GET /api/eco/points/stats?days=30 -> ok:true
3) Abra a página patchada e veja a “Vitrine (últimos 30 dias)”
4) Se existir rota de update que tentava setar status=RESOLVED, agora deve dar error resolve_via_mutirao
