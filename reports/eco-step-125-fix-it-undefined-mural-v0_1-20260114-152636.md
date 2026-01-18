# eco-step-125-fix-it-undefined-mural-v0_1

- Time: 20260114-152636
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-152636-eco-step-125-fix-it-undefined-mural-v0_1
- Bootstrap: OK

## MuralClient.tsx
- hasDeclIt: False
- hits(it./it?. /it[): 1
  - L8: <a href={"https://www.openstreetmap.org/?mlat=" + String(it.lat) + "&mlon=" + String(it.lng) + "#map=19/" + String(it.lat) + "/" + String(it.lng)} target="_blank" rel="noreferrer" style={{ fontSize: 12, fontWeight: 900, textDecoration: "none", border: "1px solid #111", borderRadius: 999, padding: "6px 10px", background: "#fff", display: "inline-flex", gap: 6, alignItems: "center", marginTop: 6 }}>🗺️ Mapa</a>
- patched: replaced it.* -> p.*

## MuralAcoesClient.tsx
- hasDeclIt: False
- hits(it./it?. /it[): 1
  - L23: <a href={"https://www.openstreetmap.org/?mlat=" + String(it.lat) + "&mlon=" + String(it.lng) + "#map=19/" + String(it.lat) + "/" + String(it.lng)} target="_blank" rel="noreferrer" style={{ fontSize: 12, fontWeight: 900, textDecoration: "none", border: "1px solid #111", borderRadius: 999, padding: "6px 10px", background: "#fff", display: "inline-flex", gap: 6, alignItems: "center", marginTop: 6 }}>🗺️ Mapa</a>
- patched: replaced it.* -> item.*

## Summary
- patchedFiles: 2

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (sem 'it is not defined')
3) abrir /eco/mapa
