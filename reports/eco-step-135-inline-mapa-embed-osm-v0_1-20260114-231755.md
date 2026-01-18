# eco-step-135-inline-mapa-embed-osm-v0_1  - stamp: 20260114-231755

## DIAG
Root: C:\Projetos\App ECO\eluta-servicos
Bootstrap: True

## PATCH
- updated: C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\_components\MuralInlineMapa.tsx
- skip: C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\page.tsx (já tem MuralInlineMapa)

## VERIFY
- Ctrl+C -> npm run dev
- abrir /eco/mural
- clicar **🗺️ Ver mapa aqui** (e conferir iframe)
- teste foco: /eco/mural?map=1&focus=<id>