-- AlterTable
ALTER TABLE "User" DROP COLUMN "jagoWalletId";

-- CreateTable
CREATE TABLE "JagoKantong" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "walletId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "JagoKantong_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "JagoKantong_userId_key_key" ON "JagoKantong"("userId", "key");

-- AddForeignKey
ALTER TABLE "JagoKantong" ADD CONSTRAINT "JagoKantong_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JagoKantong" ADD CONSTRAINT "JagoKantong_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "Wallet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
