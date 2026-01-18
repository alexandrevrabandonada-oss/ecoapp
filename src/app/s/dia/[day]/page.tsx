import type { Metadata } from "next";
import { headers } from "next/headers";
import DayShareClient from "./DayShareClient";

function safeDay(input: string): string {
  const s = String(input || "").trim();
  if (s.length === 10 && /^[0-9-]+$/.test(s)) return s;
  return "2025-01-01";
}

async function originFromHeaders() {
  const h = await headers();
  const proto = h.get("x-forwarded-proto") || "http";
  const host = h.get("x-forwarded-host") || h.get("host") || "localhost:3000";
  return `${proto}://${host}`;
}

export async function generateMetadata(
  { params }: { params: Promise<{ day: string }> }
): Promise<Metadata> {
  const p = await params;
  const day = safeDay(p.day);

  const origin = await originFromHeaders();
  const og3x4 = `${origin}/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;

  return {
    title: `ECO — Fechamento do dia ${day}`,
    description: `Fechamento do dia ${day} — ECO (Escutar • Cuidar • Organizar)`,
    openGraph: {
      title: `ECO — Fechamento do dia ${day}`,
      description: `Fechamento do dia ${day} — ECO`,
      images: [{ url: og3x4, width: 1080, height: 1350 }],
    },
    twitter: {
      card: "summary_large_image",
      title: `ECO — Fechamento do dia ${day}`,
      description: `Fechamento do dia ${day} — ECO`,
      images: [og3x4],
    },
  };
}

import DayClosePanel from "./DayClosePanel";
export default async function Page(
  { params }: { params: Promise<{ day: string }> }
) {
  const p = await params;
  const day = safeDay(p.day);

  const img3x4 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;
  const img1x1 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=1x1`;

  return (
    <main style={{ maxWidth: 980, margin: "0 auto", padding: 18 }}>
      <p style={{ marginTop: 8, marginBottom: 8 }}><a href="/operador/triagem" style={{ textDecoration: "underline" }}>← Voltar para Triagem</a></p>

      <h1 style={{ fontSize: 22, fontWeight: 800 }}>ECO — Fechamento do dia</h1>
      <p style={{ opacity: 0.85, marginTop: 6 }}>
        Dia: <strong>{day}</strong>
      </p>

      <DayShareClient day={day} />

      <DayClosePanel day={day} />

      <div style={{ display: "flex", flexWrap: "wrap", gap: 18, marginTop: 18 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          <div style={{ fontWeight: 700 }}>Preview 3:4</div>
{/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={img3x4} alt={`Card 3:4 — ${day}`} width={360} height={450} style={{ borderRadius: 14, border: "1px solid #222" }} />
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          <div style={{ fontWeight: 700 }}>Preview 1:1</div>
{/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={img1x1} alt={`Card 1:1 — ${day}`} width={360} height={360} style={{ borderRadius: 14, border: "1px solid #222" }} />
        </div>
      </div>

      <p style={{ marginTop: 18, fontSize: 12, opacity: 0.75 }}>
        Recibo é lei. Cuidado é coletivo. Trabalho digno é o centro. — #ECO • Escutar • Cuidar • Organizar
      </p>
    </main>
  );
}
