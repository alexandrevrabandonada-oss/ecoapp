// ECO — Share Day Page — step 58

import ShareDayClient from "./ShareDayClient";

export const dynamic = "force-dynamic";

export default async function Page(props: { params: Promise<{ day: string }> }) {
  const params = await props.params;
  return (
    <main style={{ padding: 16, fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Arial" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>ECO — Share do Dia</h1>
      <p style={{ margin: "0 0 16px 0", opacity: 0.85 }}>
        Card + legenda prontos para postar.
      </p>
      <ShareDayClient day={params.day} />
    </main>
  );
}

