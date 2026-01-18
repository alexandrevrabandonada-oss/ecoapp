import { NextResponse } from "next/server";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function cleanPrefix(v: any) {
  const s = String(v || "").trim().toLowerCase();
  if (!s) return "eco";
  return s.replace(/[^a-z0-9_-]/g, "").slice(0, 24) || "eco";
}
function extFrom(file: File) {
  const name = String((file as any).name || "");
  const t = String((file as any).type || "");
  if (t.includes("png")) return "png";
  if (t.includes("webp")) return "webp";
  if (t.includes("jpeg") || t.includes("jpg")) return "jpg";
  const m = name.toLowerCase().match(/\.([a-z0-9]{1,5})$/);
  if (m && m[1]) return m[1];
  return "jpg";
}

export async function POST(req: Request) {
  try {
    const form = await req.formData();
    const file = form.get("file");
    const prefix = cleanPrefix(form.get("prefix"));
    if (!file || !(file instanceof File)) {
      return NextResponse.json({ ok: false, error: "missing_file" }, { status: 400 });
    }
    const maxBytes = 6 * 1024 * 1024;
    const size = Number((file as any).size || 0);
    if (size <= 0) return NextResponse.json({ ok: false, error: "bad_file" }, { status: 400 });
    if (size > maxBytes) return NextResponse.json({ ok: false, error: "too_big", maxBytes }, { status: 413 });

    const ab = await file.arrayBuffer();
    const buf = Buffer.from(ab);

    const now = new Date();
    const yyyy = String(now.getFullYear());
    const mm = String(now.getMonth() + 1).padStart(2, "0");
    const ext = extFrom(file);
    const name = prefix + "_" + now.getTime() + "_" + crypto.randomUUID().slice(0, 8) + "." + ext;

    const relDir = path.join("public", "eco-uploads", yyyy, mm);
    const absDir = path.join(process.cwd(), relDir);
    await mkdir(absDir, { recursive: true });

    const absFile = path.join(absDir, name);
    await writeFile(absFile, buf);

    const url = "/eco-uploads/" + yyyy + "/" + mm + "/" + name;
    return NextResponse.json({ ok: true, url, bytes: buf.length, type: String((file as any).type || "") });
  } catch (e: any) {
    const msg = e && e.message ? String(e.message) : "upload_failed";
    return NextResponse.json({ ok: false, error: "upload_failed", detail: msg }, { status: 500 });
  }
}
