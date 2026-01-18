"use client";

import { useEffect, useMemo, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";

type Pt = {
  id: string;
  lat?: number | null;
  lng?: number | null;
  latitude?: number | null;
  longitude?: number | null;
  kind?: string | null;
  bairro?: string | null;
};

type ApiResp = { items?: Pt[] };

function num(v: any): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function latOf(p: Pt): number {
  return num((p as any).lat ?? (p as any).latitude);
}
function lngOf(p: Pt): number {
  return num((p as any).lng ?? (p as any).longitude);
}

function buildOsmSrc(lat: number, lng: number): string {
  const dLat = 0.01;
  const dLng = 0.01;
  const left = (lng - dLng).toFixed(6);
  const bottom = (lat - dLat).toFixed(6);
  const right = (lng + dLng).toFixed(6);
  const top = (lat + dLat).toFixed(6);
  const bbox = [left, bottom, right, top].join("%2C");
  const marker = encodeURIComponent(lat.toFixed(6) + "," + lng.toFixed(6));
  return "https://www.openstreetmap.org/export/embed.html?bbox=" + bbox + "&layer=mapnik&marker=" + marker;
}

function buildOsmLink(lat: number, lng: number): string {
  const a = lat.toFixed(6);
  const o = lng.toFixed(6);
  return "https://www.openstreetmap.org/?mlat=" + a + "&mlon=" + o + "#map=17/" + a + "/" + o;
}

export default function MuralInlineMapa() {
  const sp = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();

  const focus = sp.get("focus") || "";
  const wantOpen = sp.get("map") === "1";

  const [open, setOpen] = useState<boolean>(wantOpen);
  const [items, setItems] = useState<Pt[]>([]);
  const [loading, setLoading] = useState<boolean>(false);

  useEffect(() => {
    setOpen(wantOpen);
  }, [wantOpen]);

  useEffect(() => {
    if (!open) return;
    let alive = true;
    setLoading(true);
    fetch("/api/eco/points?limit=200", { cache: "no-store" })
      .then((r) => r.json())
      .then((j: ApiResp) => {
        if (!alive) return;
        setItems(Array.isArray(j?.items) ? j.items : []);
      })
      .catch(() => {
        if (!alive) return;
        setItems([]);
      })
      .finally(() => {
        if (!alive) return;
        setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, [open]);

  const focused = useMemo(() => {
    const arr = items || [];
    const byId = focus ? arr.find((p) => String((p as any).id) === String(focus)) : undefined;
    if (byId && latOf(byId) && lngOf(byId)) return byId;
    const anyPt = arr.find((p) => latOf(p) && lngOf(p));
    return anyPt || null;
  }, [items, focus]);

  const center = useMemo(() => {
    if (focused) return { lat: latOf(focused), lng: lngOf(focused) };
    return { lat: -22.520, lng: -44.100 };
  }, [focused]);

  const src = useMemo(() => buildOsmSrc(center.lat, center.lng), [center.lat, center.lng]);
  const osmLink = useMemo(() => buildOsmLink(center.lat, center.lng), [center.lat, center.lng]);

  function toggle() {
    const next = !open;
    setOpen(next);
    const usp = new URLSearchParams(sp.toString());
    if (next) usp.set("map", "1"); else usp.delete("map");
    router.replace(pathname + (usp.toString() ? ("?" + usp.toString()) : ""), { scroll: false });
  }

  return (
    <section id="mural-mapa" style={{ marginTop: 12, marginBottom: 12 }} className="eco-mural__map">
      <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
        <button
          onClick={toggle}
          style={{
            padding: "10px 12px",
            borderRadius: 12,
            border: "1px solid #111",
            background: open ? "#111" : "#fff",
            color: open ? "#fff" : "#111",
            fontWeight: 900,
          }}
        >
          {open ? "Fechar mapa" : "🗺️ Ver mapa aqui"}
        </button>
        <a href={osmLink} target="_blank" rel="noreferrer" style={{ fontWeight: 800, textDecoration: "underline" }}>
          Abrir no OpenStreetMap
        </a>
        {focused ? (
          <span style={{ opacity: 0.85, fontSize: 12 }}>
            foco: {(focused as any).kind || "ponto"} {(focused as any).bairro ? ("• " + String((focused as any).bairro)) : ""}
          </span>
        ) : null}
      </div>

      {open ? (
        <div style={{ marginTop: 10, borderRadius: 16, overflow: "hidden", border: "1px solid #111" }}>
          <iframe className="eco-mural__mapIframe"             title="Mapa do Cuidado"
            src={src}
            style={{ width: "100%", height: 520, border: 0, display: "block" }}
            loading="lazy"
          />
          <div style={{ padding: 10, background: "#fff", borderTop: "1px solid #111", fontSize: 12 }}>
            {loading ? "Carregando pontos..." : (items.length ? ("Pontos carregados: " + items.length) : "Sem pontos com coordenadas ainda.")}{" "}
            Dica: abrir já focando: <code>?map=1&amp;focus=&lt;id&gt;</code>.
          </div>
        </div>
      ) : null}
    </section>
  );
}
