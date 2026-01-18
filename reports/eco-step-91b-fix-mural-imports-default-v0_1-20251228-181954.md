# eco-step-91b-fix-mural-imports-default-v0_1

- Time: 
20251228-181954
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-181954-eco-step-91b-fix-mural-imports-default-v0_1

## Changes
- MuralClient: PointActionsInline import agora e relativo (../_components/PointActionsInline).
- MuralClient: garante export default function MuralClient.
- mural/page.tsx: garante import default MuralClient from ./MuralClient.
- chamados/page.tsx: garante import default MuralClient from ../MuralClient.

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (deve 200)
3) abrir /eco/mural/chamados (deve 200)