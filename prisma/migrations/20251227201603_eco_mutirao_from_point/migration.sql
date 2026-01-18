-- CreateTable
CREATE TABLE "EcoMutirao" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "pointId" TEXT NOT NULL,
    "title" TEXT,
    "note" TEXT,
    "startAt" DATETIME NOT NULL,
    "durationMin" INTEGER NOT NULL DEFAULT 90,
    "status" TEXT NOT NULL DEFAULT 'SCHEDULED',
    "beforeUrl" TEXT,
    "afterUrl" TEXT,
    "checklist" JSONB,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "EcoMutirao_pointId_fkey" FOREIGN KEY ("pointId") REFERENCES "EcoCriticalPoint" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "EcoMutirao_pointId_key" ON "EcoMutirao"("pointId");

-- CreateIndex
CREATE INDEX "EcoMutirao_startAt_idx" ON "EcoMutirao"("startAt");
