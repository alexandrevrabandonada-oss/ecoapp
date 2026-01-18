-- CreateTable
CREATE TABLE "EcoPointReplicate" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "pointId" TEXT NOT NULL,
    "fingerprint" TEXT NOT NULL,
    CONSTRAINT "EcoPointReplicate_pointId_fkey" FOREIGN KEY ("pointId") REFERENCES "EcoCriticalPoint" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "EcoPointReplicate_pointId_idx" ON "EcoPointReplicate"("pointId");

-- CreateIndex
CREATE UNIQUE INDEX "EcoPointReplicate_pointId_fingerprint_key" ON "EcoPointReplicate"("pointId", "fingerprint");
