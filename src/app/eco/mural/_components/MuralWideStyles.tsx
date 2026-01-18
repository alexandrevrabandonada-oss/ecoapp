"use client";

export default function MuralWideStyles() {
  return (
    <style>{`
/* ECO — Mural: split + mapa sticky (map=1) */
.eco-mural {
  background: #070b08 !important;
  color: #eaeaea !important;
  max-width: min(1700px, calc(100% - 32px)) !important;
  margin: 0 auto !important;
  padding: 18px 0 60px !important;
}

.eco-mural-split {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
  align-items: start;
}
.eco-mural-right { display: none; }
.eco-mural[data-map="1"] .eco-mural-right { display: block; }

@media (min-width: 1100px) {
  .eco-mural[data-map="1"] .eco-mural-split {
    grid-template-columns: minmax(640px, 1fr) 600px;
    gap: 18px;
  }
  .eco-mural[data-map="1"] .eco-mural-right {
    position: sticky;
    top: 86px;
    align-self: start;
  }
}

.eco-mural iframe[src*="openstreetmap.org"] {
  width: 100% !important;
  height: 420px !important;
  border: 0 !important;
  display: block !important;
  border-radius: 14px !important;
}
@media (min-width: 1100px) {
  .eco-mural iframe[src*="openstreetmap.org"] {
    height: calc(100vh - 160px) !important;
    min-height: 520px !important;
  }
}

@media (min-width: 900px) {
  .eco-mural .eco-mural-cards {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 14px;
  }
}
`}</style>
  );
}