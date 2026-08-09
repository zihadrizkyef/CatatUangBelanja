-- CreateEnum
CREATE TYPE "TransactionSource" AS ENUM ('Manual', 'EmailSync');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "jagoRefreshToken" TEXT,
ADD COLUMN     "jagoWalletId" TEXT,
ADD COLUMN     "jagoHistoryId" TEXT,
ADD COLUMN     "jagoConnectedAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN     "source" "TransactionSource" NOT NULL DEFAULT 'Manual',
ADD COLUMN     "externalId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "Transaction_externalId_key" ON "Transaction"("externalId");
