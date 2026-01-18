"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";

export default function MuralTopBarClient(){
  const pathname = usePathname();
  const tabs = [
    { href: "/eco/mural", label: "Mural" },
    { href: "/eco/mural-acoes", label: "Acoes" },
    { href: "/eco/pontos", label: "Pontos" },
    { href: "/eco/mutiroes", label: "Mutiroes" },
  ];
  return (
    <div className="mb-4 flex flex-wrap gap-2">
      {tabs.map((t) => {
        const active = pathname ? pathname.startsWith(t.href) : false;
        const cls = "rounded-full px-3 py-1 text-sm " + (active ? "bg-amber-400 text-black" : "border border-neutral-800 text-neutral-200");
        return (
          <Link key={t.href} href={t.href} className={cls}>{t.label}</Link>
        );
      })}
    </div>
  );
}
