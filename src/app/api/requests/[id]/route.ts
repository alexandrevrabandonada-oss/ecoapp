import { NextResponse } from "next/server";
export const runtime = "nodejs";

export async function GET(req: Request, ctx: any) {
  const mod: any = await import("../../pickup-requests/[id]/route");
  if (typeof mod.GET === "function") return mod.GET(req, ctx);
  return NextResponse.json({ error: "pickup_requests_id_get_missing" }, { status: 500 });
}

export async function PATCH(req: Request, ctx: any) {
  const mod: any = await import("../../pickup-requests/[id]/route");
  if (typeof mod.PATCH === "function") return mod.PATCH(req, ctx);
  return NextResponse.json({ error: "pickup_requests_id_patch_missing" }, { status: 500 });
}