-- CreateTable
CREATE TABLE "EcoCriticalPoint" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "kind" TEXT NOT NULL,
    "lat" REAL NOT NULL,
    "lng" REAL NOT NULL,
    "note" TEXT,
    "photoUrl" TEXT,
    "actor" TEXT,
    "confirmCount" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'OPEN',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "EcoCriticalPointConfirm" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "pointId" TEXT NOT NULL,
    "actor" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "EcoCriticalPointConfirm_pointId_fkey" FOREIGN KEY ("pointId") REFERENCES "EcoCriticalPoint" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "EcoCriticalPointConfirm_pointId_idx" ON "EcoCriticalPointConfirm"("pointId");

-- CreateIndex
CREATE UNIQUE INDEX "EcoCriticalPointConfirm_pointId_actor_key" ON "EcoCriticalPointConfirm"("pointId", "actor");
