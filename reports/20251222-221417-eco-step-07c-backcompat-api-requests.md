# ECO — STEP 07c — Backcompat /api/requests + /pedidos/fechar (sem id)

Data: 2025-12-22 22:14:17
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG — ocorrências de /api/requests
- C:/Projetos/App ECO/eluta-servicos/src/app/chamar/page.tsx:62 :: const res = await fetch("/api/requests", {
- C:/Projetos/App ECO/eluta-servicos/src/app/pedidos/page.tsx:13 :: const res = await fetch(`${origin}/api/requests`, { cache: "no-store" });
- C:/Projetos/App ECO/eluta-servicos/src/app/pedidos/page.tsx:18 :: const res = await fetch(`/api/requests/${id}`, {

Backup: tools/_patch_backup/20251222-221418-src_app_api_requests_[id]_route.ts
- OK: criado proxy /api/requests/[id] -> /api/pickup-requests/[id]
- OK: criado proxy /api/requests -> /api/pickup-requests

- OK: criado /pedidos/fechar (page.tsx) amigável

## DIAG (depois)
Exists /api/requests route? True
Exists /api/requests/[id] route? True
Exists /pedidos/fechar page? True
