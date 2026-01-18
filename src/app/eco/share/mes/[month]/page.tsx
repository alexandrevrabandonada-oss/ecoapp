import ShareMonthClient from "./ShareMonthClient";

export const dynamic = "force-dynamic";

export default async function Page(props: any) {
  const p0 = props?.params;
  const resolved = p0 && typeof p0.then === "function" ? await p0 : p0;
  const month = String(resolved?.month || "");

  return (
    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>Compartilhar mês: {month || "—"}</h1>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Card + legenda prontos para postar.</p>
      <ShareMonthClient month={month} />
    </main>
  );
}

