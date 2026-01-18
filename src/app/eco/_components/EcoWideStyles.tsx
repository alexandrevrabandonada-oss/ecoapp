export default function EcoWideStyles() {
  const css = [
    "main[data-eco-wide='1'] { max-width: none !important; width: min(1700px, calc(100% - 32px)) !important; margin: 0 auto !important; padding: 18px 0 60px !important; }",
    "@media (max-width: 640px) { main[data-eco-wide='1'] { width: calc(100% - 16px) !important; padding: 12px 0 48px !important; } }",
    "main[data-eco-wide='1'] * { box-sizing: border-box; }",
    "iframe[src*='openstreetmap.org'][src*='embed'] { width: 100% !important; max-width: 100% !important; border: 1px solid #111 !important; border-radius: 12px !important; }",
    "@media (min-width: 900px) { iframe[src*='openstreetmap.org'][src*='embed'] { height: 420px !important; } }",
    "@media (max-width: 899px) { iframe[src*='openstreetmap.org'][src*='embed'] { height: 320px !important; } }",
  ].join("\\n");
  return <style>{css}</style>;
}