import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { RequestStatus } from "@prisma/client";

function makeCode(len = 8) {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let out = "";
  for (let i = 0; i < len; i++) out += chars[Math.floor(Math.random() * chars.length)];
  return out;
}

export async function PUT(req: Request, { params }: any) {
  const id = String(params?.id ?? "");
  const body = await req.json().catch(() => ({} as any));
  const status = body?.status as RequestStatus;

  const valid = [
    RequestStatus.OPEN,
    RequestStatus.TRIAGED,
    RequestStatus.SCHEDULED,
    RequestStatus.DONE,
    RequestStatus.CANCELED,
  ];

  if (!id) return NextResponse.json({ error: "id ausente" }, { status: 400 });
  if (!valid.includes(status)) return NextResponse.json({ error: "status invalido" }, { status: 400 });

  const updated = await prisma.pickupRequest.update({
    where: { id },
    data: { status },
  });

  let receipt: any = null;

  if (status === RequestStatus.DONE) {
    receipt = await prisma.receipt.findUnique({ where: { requestId: id } }).catch(() => null);

    if (!receipt) {
      for (let i = 0; i < 6; i++) {
        const code = makeCode(8);
        try {
          receipt = await prisma.receipt.create({ data: { code, requestId: id } });
          break;
        } catch {
          // colisao rara de code unico -> tenta de novo
        }
      }
    }
  }

  return NextResponse.json({ request: updated, receipt });
}