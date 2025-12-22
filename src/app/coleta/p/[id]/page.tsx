import PontoClient from "./ponto-client";

export default async function PontoPage({ params }: { params: Promise<{ id: string }> | { id: string } }) {
  const p: any = params as any;
  const id = (typeof (p?.then) === "function") ? (await p).id : p.id;
  return <PontoClient id={id} />;
}