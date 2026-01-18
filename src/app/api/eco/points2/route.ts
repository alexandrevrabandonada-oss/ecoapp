import { NextResponse } from "next/server";

export const runtime = "nodejs";

export async function GET(req: Request) {
  const url = new URL(req.url);
  url.pathname = "/api/eco/points/list";
  const res = await fetch(url.toString(), { method: "GET", headers: req.headers, cache: "no-store" });
  const body = await res.text();
  return new NextResponse(body, { status: res.status, headers: { "content-type": "application/json; charset=utf-8" } });
}