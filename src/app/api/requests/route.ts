export const runtime = "nodejs";

// Alias: mantém compatibilidade com telas/links antigos (/api/requests),
// mas usa a lógica oficial do endpoint novo (/api/pickup-requests).
export { GET, POST } from "../pickup-requests/route";
