import MuralReadableStyles from "./_components/MuralReadableStyles";
import MuralWideStyles from "./_components/MuralWideStyles";
import MapToggleLink from "./_components/MapToggleLink";
import MuralNavPillsClient from "./_components/MuralNavPillsClient";
import MuralNewPointClient from "./_components/MuralNewPointClient";
import MuralInlineMapa from "./_components/MuralInlineMapa";
import MuralClient from "./MuralClient";

export default async function Page({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = (await searchParams) ?? {};
  const mapRaw = (sp as any).map;
  const mapVal = Array.isArray(mapRaw) ? mapRaw[0] : mapRaw;
  const mapOpen = (mapVal === "1" || mapVal === "true");

  return (
    <main className="eco-mural" data-eco-wide="1" data-map={mapOpen ? "1" : "0"} style={{ padding: 16 }}>
      <MuralReadableStyles />
      <MuralWideStyles />
      <div style={{ display: "flex", justifyContent: "flex-end", gap: 10, margin: "10px 0 14px" }}>
        <MapToggleLink />
      </div>

      <div className="eco-mural-split">
        <div className="eco-mural-left">
          <MuralNavPillsClient />
          <MuralNewPointClient />
          <MuralClient base="pontos" />
        </div>

        <div className="eco-mural-right">
          <MuralInlineMapa />
        </div>
      </div>
    </main>
  );
}
