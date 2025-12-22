import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

const defaults = [
  { name: "Coleta Solidária", kind: "COLETA", slug: "coleta-solidaria" },
  { name: "Reparo & Reuso", kind: "REPARO", slug: "reparo-reuso" },
  { name: "Feira Comunitária", kind: "FEIRA", slug: "feira-comunitaria" },
  { name: "Formação Popular", kind: "FORMACAO", slug: "formacao-popular" },
  { name: "Doação", kind: "DOACAO", slug: "doacao" },
];

async function main() {
  const count = await prisma.service.count();
  if (count > 0) {
    console.log("Seed: serviços já existem (count =", count, ")");
    return;
  }
  for (const s of defaults) await prisma.service.create({ data: s });
  console.log("Seed: OK (", defaults.length, "serviços criados )");
}

main()
  .catch((e) => { console.error("Seed error:", e?.message ?? e); process.exitCode = 1; })
  .finally(async () => prisma.$disconnect());