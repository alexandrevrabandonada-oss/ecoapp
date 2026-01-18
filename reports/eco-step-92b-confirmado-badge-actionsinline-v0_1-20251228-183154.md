# eco-step-92b-confirmado-badge-actionsinline-v0_1

- Time: 
20251228-183154
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-183154-eco-step-92b-confirmado-badge-actionsinline-v0_1

## Changes
- Added: src/app/eco/_components/ConfirmadoBadge.tsx
- Patched: src/app/eco/_components/PointActionsInline.tsx (import + badge render)

## Badge data expression
- 
(props as any).point ?? (props as any).item ?? (props as any).data ?? (props as any)

## Verify
1) Ctrl+C -> npm run dev
2) /eco/mural e /eco/mural/chamados
3) Em pontos com contagem/confirmacoes no payload, aparece ✅ CONFIRMADO + numero