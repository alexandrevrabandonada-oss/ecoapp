"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export default function MuralNavPillsClient() {
  const pathname = usePathname() || "";
  const isChamados = pathname === "/eco/mural/chamados";
  const isConfirmados = pathname === "/eco/mural/confirmados";

  const base: any = { padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", fontWeight: 900 };
  const on: any = { background: "#111", color: "#fff" };
  const off: any = { background: "#fff", color: "#111" };

  return (
    <div style={{ margin: "10px 0 14px 0", display: "flex", gap: 8, flexWrap: "wrap" }}>
      <Link href="/eco/mural/chamados" style={{ ...base, ...(isChamados ? on : off) }}>
        📣 Chamados
      </Link>
      <Link href="/eco/mural/confirmados" style={{ ...base, ...(isConfirmados ? on : off) }}>
        ✅ Confirmados
      </Link>
    </div>
  );
}
