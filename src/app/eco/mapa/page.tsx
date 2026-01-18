import MuralReadableStyles from "../mural/_components/MuralReadableStyles";
import MapaClient from "./_components/MapaClient";
import EcoWideStyles from '../_components/EcoWideStyles'

export const dynamic = "force-dynamic";

export default function Page() {
  return (
    <main className="eco-mural" data-eco-wide="1">
      <EcoWideStyles />
      <MuralReadableStyles />
      <div className="eco-mural-inner">
        <h1>Mapa do Cuidado</h1>
        <p>Selecione um ponto e confirme/apoie/replica. O mapa abre no OpenStreetMap.</p>
        <MapaClient />
      </div>
    </main>
  );
}