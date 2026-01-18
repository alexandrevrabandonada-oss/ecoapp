-- CreateTable
CREATE TABLE "PickupRequest" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'OPEN',
    "routeDay" TEXT,
    "collectedAt" DATETIME
);

-- CreateTable
CREATE TABLE "Service" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "kind" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Point" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "serviceId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "lat" REAL,
    "lng" REAL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "neighborhood" TEXT,
    "hours" TEXT,
    CONSTRAINT "Point_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "Service" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Delivery" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "pointId" TEXT NOT NULL,
    "material" TEXT NOT NULL,
    "notes" TEXT,
    "weightKg" REAL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Delivery_pointId_fkey" FOREIGN KEY ("pointId") REFERENCES "Point" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Weighing" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "pointId" TEXT NOT NULL,
    "material" TEXT NOT NULL,
    "weightKg" REAL NOT NULL,
    "notes" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Weighing_pointId_fkey" FOREIGN KEY ("pointId") REFERENCES "Point" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Receipt" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "code" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "requestId" TEXT NOT NULL,
    "public" BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT "Receipt_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "PickupRequest" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "EcoReceipt" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "shareCode" TEXT NOT NULL,
    "public" BOOLEAN NOT NULL DEFAULT false,
    "summary" TEXT,
    "items" TEXT,
    "operator" TEXT,
    "requestId" TEXT NOT NULL,
    CONSTRAINT "EcoReceipt_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "PickupRequest" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "EcoDayClose" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "day" TEXT NOT NULL,
    "summary" JSONB NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "Service_slug_key" ON "Service"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Point_slug_key" ON "Point"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Receipt_code_key" ON "Receipt"("code");

-- CreateIndex
CREATE UNIQUE INDEX "Receipt_requestId_key" ON "Receipt"("requestId");

-- CreateIndex
CREATE UNIQUE INDEX "EcoReceipt_shareCode_key" ON "EcoReceipt"("shareCode");

-- CreateIndex
CREATE UNIQUE INDEX "EcoReceipt_requestId_key" ON "EcoReceipt"("requestId");

-- CreateIndex
CREATE UNIQUE INDEX "EcoDayClose_day_key" ON "EcoDayClose"("day");
