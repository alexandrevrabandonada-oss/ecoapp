import { readFile } from "fs/promises";
import path from "path";

export type CadernoMeta = Record<string, unknown>;

function isRecord(v: unknown): v is Record<string, unknown> {
  return !!v && typeof v === "object" && !Array.isArray(v);
}

export async function loadCadernoMeta(slug: string): Promise<CadernoMeta> {
  const safeSlug = (slug || "").trim();
  if (!safeSlug) return {};
  const base = path.join(process.cwd(), "content", "cadernos", safeSlug);
  const file = path.join(base, "meta.json");
  try {
    const raw = await readFile(file, "utf8");
    const json = JSON.parse(raw) as unknown;
    return isRecord(json) ? (json as CadernoMeta) : {};
  } catch {
    return {};
  }
}