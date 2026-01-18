-- CreateTable
CREATE TABLE "EcoPointSupport" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "pointId" TEXT NOT NULL,
    "note" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "EcoPointSupport_pointId_fkey" FOREIGN KEY ("pointId") REFERENCES "EcoCriticalPoint" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "EcoPointSupport_pointId_idx" ON "EcoPointSupport"("pointId");
