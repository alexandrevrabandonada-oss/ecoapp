# eco-step-102-fix-pointid-bareidentifiers-v0_1

- Time: 20251229-135552
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-135552-eco-step-102-fix-pointid-bareidentifiers-v0_1

## Patched files
- (none)

## Suspicious remaining lines (review if crash persists)
- src\app\api\eco\critical\confirm\route.ts:29 | const created = await cm.create({ data: { pointId, actor } }).then(() => true).catch(() => false);
- src\app\api\eco\critical\confirm\route.ts:31 | const item = await model.update({ where: { id: pointId }, data: { confirmCount: { increment: 1 } } });
- src\app\api\eco\critical\confirm\route.ts:34 | const item = await model.findUnique({ where: { id: pointId } });
- src\app\api\eco\mural\list\route.ts:59 | // 1) tenta groupBy(pointId)
- src\app\api\eco\mural\list\route.ts:62 | const rows = await confirmModel.groupBy({ by: ["pointId"], _count: { _all: true } });
- src\app\api\eco\mutirao\create\route.ts:39 | where: { pointId },
- src\app\api\eco\mutirao\create\route.ts:43 | await p.update({ where: { id: pointId }, data: { status: "MUTIRAO" } }).catch(() => null);
- src\app\api\eco\mutirao\finish\route.ts:63 | const cur = await pm.model.findUnique({ where: { id: pointId } });
- src\app\api\eco\mutirao\finish\route.ts:85 | const item = await pm.model.update({ where: { id: pointId }, data: { status: "RESOLVED", meta } });
- src\app\api\eco\points\replicar\route.ts:47 | existed = await model.findUnique({ where: { pointId_fingerprint: { pointId, fingerprint: fp } } } as any);
- src\app\api\eco\points\replicar\route.ts:49 | existed = await model.findFirst({ where: { pointId, fingerprint: fp } } as any);
- src\app\api\eco\points\replicar\route.ts:55 | try { await model.create({ data: { pointId, fingerprint: fp } } as any); } catch (e) {}
- src\app\api\eco\points\replicar\route.ts:58 | const count = await model.count({ where: { pointId } } as any).catch(() => 0);
- src\app\api\eco\points\support\route.ts:28 | const row = await support.create({ data: { pointId, note } });
- src\app\eco\_components\EcoPointResolutionPanel.tsx:42 | }, [pointId]);
- src\app\eco\_components\PointActionsInline.tsx:6 | <PointReplicarButton pointId={pointId} counts={counts} />
- src\app\eco\_components\PointReplicarButton.tsx:28 | body: JSON.stringify({ pointId }),

## Verify
1) Ctrl+C -> npm run dev
2) GET http://localhost:3000/api/eco/points/list2?limit=10
3) Abrir /eco/mural/confirmados (sem ReferenceError)
