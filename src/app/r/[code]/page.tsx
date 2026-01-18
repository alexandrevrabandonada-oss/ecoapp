import { notFound } from 'next/navigation';
import { PrismaClient } from '@prisma/client';

import ReceiptShareBar from '../../../components/eco/ReceiptShareBar';

// ECO_STEP29_METADATA_START
import { headers } from 'next/headers';

async function ecoOriginFromHeaders(): Promise<string> {
  const h = await headers();
  const proto = h.get('x-forwarded-proto') ?? 'http';
  const host = h.get('x-forwarded-host') ?? h.get('host') ?? 'localhost:3000';
  return proto + '://' + host;
}

export async function generateMetadata({ params }: { params: { code: string } }) {
  const code = params?.code ?? '';
  const origin = await ecoOriginFromHeaders();
  const base = new URL(origin);

  const c = encodeURIComponent(String(code));
  const img34 = '/api/share/receipt-card?code=' + c + '&format=3x4';
  const img11 = '/api/share/receipt-card?code=' + c + '&format=1x1';

  return {
    metadataBase: base,
    title: 'Recibo ECO #' + String(code),
    description: 'Recibo ECO público — código ' + String(code),
    alternates: { canonical: '/r/' + String(code) },
    openGraph: {
      title: 'Recibo ECO #' + String(code),
      description: 'Recibo ECO público — código ' + String(code),
      url: '/r/' + String(code),
      type: 'article',
      images: [
        { url: img34, width: 1080, height: 1350, alt: 'Recibo ECO 3:4' },
        { url: img11, width: 1080, height: 1080, alt: 'Recibo ECO 1:1' }
      ]
    },
    twitter: {
      card: 'summary_large_image',
      title: 'Recibo ECO #' + String(code),
      description: 'Recibo ECO público — código ' + String(code),
      images: [img34]
    }
  } as any;
}
// ECO_STEP29_METADATA_END

export const runtime = 'nodejs';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

type Params = { code: string };

export default async function PublicReceiptPage({ params }: { params: Promise<Params> }) {
  const { code } = await params;

  const CODE_FIELD = 'code';
  const where: any = { [CODE_FIELD]: code };

  const receipt = await (prisma as any).receipt.findUnique({ where });

  if (!receipt) return notFound();

  const PUBLIC_FIELD = 'public';
  const isPublic = (receipt as any)?.[PUBLIC_FIELD] === true;
  if (!isPublic) return notFound();

  return (
    <main style={{ maxWidth: 860, margin: '0 auto', padding: 16 }}>
      <ReceiptShareBar code={String((params as any)?.code ?? (params as any)?.id ?? '')} />

      <h1 style={{ fontSize: 22, fontWeight: 800 }}>Recibo ECO</h1>
      <p style={{ opacity: 0.8, marginTop: 6 }}>
        Código: <strong>{code}</strong>
      </p>

      <div style={{ marginTop: 16, border: '1px solid rgba(0,0,0,0.12)', borderRadius: 12, padding: 12 }}>
        <p style={{ fontWeight: 700, marginBottom: 8 }}>Resumo (MVP)</p>
        <pre style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word', margin: 0 }}>
{JSON.stringify(receipt, null, 2)}
        </pre>
      </div>

      <div style={{ marginTop: 18, opacity: 0.85, fontSize: 13 }}>
        <p style={{ margin: 0 }}>
          #ÉLUTA — Escutar • Cuidar • Organizar
        </p>
      </div>
    </main>
  );
}