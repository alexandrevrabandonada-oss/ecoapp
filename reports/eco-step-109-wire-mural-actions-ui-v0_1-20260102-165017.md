# eco-step-109-wire-mural-actions-ui-v0_1

- Time: 20260102-165017
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-165017-eco-step-109-wire-mural-actions-ui-v0_1

## What/Why
- Ligou UI do Mural às ações (confirm/support/replicar) via POST /api/eco/points/{acao}.
- Update otimista de contadores + router.refresh() para revalidar.
- Reescreveu MuralAcoesClient.tsx de forma robusta (props:any) para não quebrar import/export existentes.

## Patched
- src/lib/eco/muralActions.ts
- C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural-acoes\MuralAcoesClient.tsx

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural
3) clicar ✅/🤝/♻️ num card (contadores devem subir)
4) conferir via API:
   irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 80
