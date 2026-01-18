# ECO — STEP 28c — ReceiptShareBar: Baixar 1:1 + Web Share (imagem) + Copiar/Compartilhar link (SAFE)

Data: 2025-12-25 18:35:44
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/components/eco/ReceiptShareBar.tsx

## PATCH
Backup: tools/_patch_backup/20251225-183544-src_components_eco_ReceiptShareBar.tsx
- OK: removi bloco antigo de helpers (len 3429 -> 1898).
- OK: helpers inseridos após 'use client'.
- INFO: botão 'Baixar card 1:1' já existe (skip).

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra a página do recibo (/r/[code]) e teste:
   - Baixar card 3:4 e 1:1
   - Compartilhar 3:4 e 1:1 (no celular/PWA abre share sheet; senão faz download)
   - Copiar link / Compartilhar link