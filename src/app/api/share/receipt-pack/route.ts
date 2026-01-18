import JSZip from "jszip";
import { NextResponse } from "next/server";

export const runtime = "nodejs";

export async function GET(req: Request) {
  const url = new URL(req.url);
  const code = (url.searchParams.get("code") ?? "").trim();

  if (!code) {
    return NextResponse.json({ error: "missing code" }, { status: 400 });
  }

  const origin = url.origin;
  const enc = encodeURIComponent(code);

  const card3 = origin + "/api/share/receipt-card?code=" + enc + "&format=3x4";
  const card1 = origin + "/api/share/receipt-card?code=" + enc + "&format=1x1";
  const publicUrl = origin + "/r/" + enc;

  const [r3, r1] = await Promise.all([
    fetch(card3, { cache: "no-store" }),
    fetch(card1, { cache: "no-store" }),
  ]);

  if (!r3.ok || !r1.ok) {
    return NextResponse.json(
      { error: "failed to render cards", ok3: r3.ok, ok1: r1.ok },
      { status: 500 }
    );
  }

  const b3 = await r3.arrayBuffer();
  const b1 = await r1.arrayBuffer();

  const captionShort =
    "Recibo ECO #" + code + "\n" +
    "Escutar • Cuidar • Organizar\n" +
    "Acesse e compartilhe: " + publicUrl;

  const captionLong =
    "Recibo ECO #" + code + "\n\n" +
    "Isso aqui é prova de cuidado, não é 'like'.\n" +
    "Recibo é transparência: mostra a ação, ajuda a organizar o bairro e fortalece a cooperativa.\n\n" +
    "Link público do recibo:\n" + publicUrl + "\n\n" +
    "#ECO #ReciboECO #EscutarCuidarOrganizar";

  const zap =
    "Bora de recibo? ♻️\n" +
    "Aqui tá o meu Recibo ECO #" + code + ":\n" +
    publicUrl;

  const meta = {
    code,
    publicUrl,
    generatedAt: new Date().toISOString(),
    files: [
      "recibo-eco-" + code + "-3x4.png",
      "recibo-eco-" + code + "-1x1.png",
      "caption.txt",
      "caption-long.txt",
      "zap.txt",
      "meta.json",
    ],
  };

  const zip = new JSZip();
  zip.file("recibo-eco-" + code + "-3x4.png", b3);
  zip.file("recibo-eco-" + code + "-1x1.png", b1);
  zip.file("caption.txt", captionShort);
  zip.file("caption-long.txt", captionLong);
  zip.file("zap.txt", zap);
  zip.file("meta.json", JSON.stringify(meta, null, 2));

  const out = await zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE" });

  return new NextResponse(new Uint8Array(out), {
    headers: {
      "Content-Type": "application/zip",
      "Content-Disposition": 'attachment; filename="eco-share-pack-' + code + '.zip"',
      "Cache-Control": "no-store",
    },
  });
}