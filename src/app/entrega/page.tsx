import EntregaForm from "./entrega-form";

export default async function EntregaPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const raw = sp?.point;
  const pointSlug = Array.isArray(raw) ? raw[0] : (raw ?? "ponto-piloto");
  return <EntregaForm pointSlug={pointSlug} />;
}
