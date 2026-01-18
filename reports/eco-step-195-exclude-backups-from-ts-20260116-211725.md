# eco-step-195 — exclude backups from TS/lint — 20260116-211725

## DIAG
- tsconfig: tsconfig.json
- backup tsconfig: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-195\20260116-211725\20260116-211725-C__Projetos_App_ECO_eluta-servicos_tsconfig.json
- rename backups (.ts/.tsx/.js/.jsx -> .bak): 254

## PATCH
- tsconfig.exclude += tools/_patch_backup, tools/_patch_backup/**, tools/**, reports/**
- .eslintignore += tools/_patch_backup/, tools/_patch_backup/**, reports/, reports/**

## VERIFY
- npm run build
