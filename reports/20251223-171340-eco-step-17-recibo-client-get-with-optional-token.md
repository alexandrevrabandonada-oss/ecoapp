# ECO — STEP 17 — /recibo/[code] (GET com token opcional para operador)

Data: 2025-12-23 17:13:40
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Recibo client: src/app/recibo/[code]/recibo-client.tsx

## PATCH
Backup Recibo: tools/_patch_backup/20251223-171340-src_app_recibo_[code]_recibo-client.tsx

- OK: /recibo/[code]/recibo-client.tsx agora envia token opcional no GET (/api/receipts?code) via header e query.

## Como testar
1) (Opcional) .env: ECO_OPERATOR_TOKEN=uma-chave-forte
2) Emita um recibo PRIVADO
3) /recibo/[code] (operador): preencher chave -> Recarregar -> deve mostrar
4) Aba anônima (sem chave): deve 404/privado
