import { GET as GET_LIST2 } from "./list2/route";
import { prisma } from "@/lib/prisma";


import { NextResponse } from "next/server";





export const runtime = "nodejs";


export const dynamic = "force-dynamic";





export async function GET(req: Request) {


  return GET_LIST2(req);


}








// --- added by tools/eco-step-112-add-create-point-and-ui-v0_2.ps1


// POST /api/eco/points : cria ponto crítico (lat/lng + defaults + best-effort required fields).


export async function POST(req: Request) {


  try {


    const body: any = await req.json().catch(() => ({}));


    const lat = Number(body.lat);


    const lng = Number(body.lng);


    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {


      return NextResponse.json({ ok: false, error: 'bad_latlng' }, { status: 400 });


    }


    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {


      return NextResponse.json({ ok: false, error: 'latlng_out_of_range' }, { status: 400 });


    }





    const actor = (typeof body.actor === 'string' && body.actor.trim().length) ? body.actor.trim().slice(0, 80) : 'anon';


    const note = (typeof body.note === 'string' && body.note.trim().length) ? body.note.trim().slice(0, 500) : null;


    const photoUrl = (typeof body.photoUrl === 'string' && body.photoUrl.trim().length) ? body.photoUrl.trim().slice(0, 500) : null;





    const pc: any = prisma as any;


    const keys = Object.keys(pc);


    const pointKey = (pc.ecoCriticalPoint ? 'ecoCriticalPoint' : (keys.find((k) => /point/i.test(k) && /eco/i.test(k)) || null));


    if (!pointKey) return NextResponse.json({ ok: false, error: 'point_model_not_found' }, { status: 500 });





    // DMMF (runtime) para validar enums e preencher required sem default


    const mod: any = await import('@prisma/client');


    const dmmf: any = mod && mod.Prisma ? (mod.Prisma as any).dmmf : null;


    const models: any[] = dmmf && dmmf.datamodel && Array.isArray(dmmf.datamodel.models) ? dmmf.datamodel.models : [];


    const enums: any[] = dmmf && dmmf.datamodel && Array.isArray(dmmf.datamodel.enums) ? dmmf.datamodel.enums : [];


    const toDelegate = (name: string) => name && name.length ? name.slice(0,1).toLowerCase() + name.slice(1) : name;


    const model = models.find((m: any) => m && toDelegate(m.name) === pointKey) || null;


    const hasField = (n: string) => !!(model && Array.isArray(model.fields) && model.fields.some((f: any) => f && f.name === n));


    const getField = (n: string) => (model && Array.isArray(model.fields) ? model.fields.find((f: any) => f && f.name === n) : null);


    const enumAllowed = (enumName: string) => {


      const e = enums.find((x: any) => x && x.name === enumName);


      return e && Array.isArray(e.values) ? e.values.map((v: any) => v && v.name).filter(Boolean) : [];


    };





    let kind = (typeof body.kind === 'string' && body.kind.trim().length) ? body.kind.trim() : 'LIXO_ACUMULADO';


    let status = (typeof body.status === 'string' && body.status.trim().length) ? body.status.trim() : 'OPEN';





    const kindField: any = getField('kind');


    if (kindField && kindField.kind === 'enum') {


      const allowed = enumAllowed(kindField.type);


      if (allowed.length && !allowed.includes(kind)) kind = allowed[0];


    }


    const statusField: any = getField('status');


    if (statusField && statusField.kind === 'enum') {


      const allowed = enumAllowed(statusField.type);


      if (allowed.length && !allowed.includes(status)) status = allowed[0];


    }





    const data: any = {};


    // id (se necessário e sem default) — best-effort


    const idField: any = getField('id');


    if (idField && idField.isRequired && !idField.hasDefaultValue) {


      data.id = (typeof body.id === 'string' && body.id.trim().length) ? body.id.trim().slice(0, 64) : ('p-' + Math.random().toString(36).slice(2,8) + '-' + Date.now().toString(36));


    }


    if (hasField('lat')) data.lat = lat;


    if (hasField('lng')) data.lng = lng;


    if (hasField('kind')) data.kind = kind;


    if (hasField('status')) data.status = status;


    if (hasField('note')) data.note = note;


    if (hasField('photoUrl')) data.photoUrl = photoUrl;


    if (hasField('actor')) data.actor = actor;


    if (hasField('createdAt')) data.createdAt = new Date();


    if (hasField('updatedAt')) data.updatedAt = new Date();





    // preencher required scalars/enums sem default (best-effort)


    if (model && Array.isArray(model.fields)) {


      for (const f of model.fields) {


        if (!f || f.isList) continue;


        if (f.kind !== 'scalar' && f.kind !== 'enum') continue;


        if (!f.isRequired) continue;


        if (f.hasDefaultValue) continue;


        if (data[f.name] !== undefined) continue;


        if (f.name === 'id') continue;


        if (f.kind === 'enum') {


          const allowed = enumAllowed(f.type);


          data[f.name] = allowed.length ? allowed[0] : kind;


          continue;


        }


        if (f.type === 'String') { data[f.name] = actor; continue; }


        if (f.type === 'Int' || f.type === 'Float') { data[f.name] = 0; continue; }


        if (f.type === 'Boolean') { data[f.name] = false; continue; }


        if (f.type === 'DateTime') { data[f.name] = new Date(); continue; }


        data[f.name] = actor;


      }


    }





    const created = await pc[pointKey].create({ data });


    return NextResponse.json({ ok: true, error: null, item: created, meta: { pointKey } }, { status: 201 });


  } catch (e: any) {


    const msg = e && e.message ? String(e.message) : String(e);


    return NextResponse.json({ ok: false, error: 'create_failed', message: msg }, { status: 500 });


  }


}


