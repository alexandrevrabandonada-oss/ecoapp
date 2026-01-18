# Tijolos PowerShell — Regras de Ouro

## 1) Sempre rode o arquivo .ps1
- Gere o .ps1 e execute: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\seu-script.ps1`
- **Nunca** cole blocos internos no prompt.

## 2) Se o prompt virar `>>`, pare
- `>>` = bloco aberto. Feche o bloco (ou CTRL+C) antes de qualquer coisa.

## 3) Funções comuns ficam no bootstrap
- Todo tijolo deve começar com: `. "$PSScriptRoot/_bootstrap.ps1"`

## 4) Antes de Replace/Insert
- Garanta `Test-Path` + `AssertNotNull $raw "..."`
    '
    
- Se o wrapper usa `$code = @' ... '@`, não use `@' ... '@` dentro.
- Prefira `@(...) -join "`n"` para gerar conteúdo.
