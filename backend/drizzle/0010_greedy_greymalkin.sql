-- Create new enums
CREATE TYPE "public"."account_type" AS ENUM('admin', 'employee', 'user');--> statement-breakpoint
CREATE TYPE "public"."status" AS ENUM('active', 'inactive');--> statement-breakpoint

-- Update existing 'student' values to 'user' before converting
UPDATE "users" SET "account_type" = 'user' WHERE "account_type" = 'student';--> statement-breakpoint

-- Convert account_type column to enum
ALTER TABLE "users" ALTER COLUMN "account_type" SET DEFAULT 'user'::"public"."account_type";--> statement-breakpoint
ALTER TABLE "users" ALTER COLUMN "account_type" SET DATA TYPE "public"."account_type" USING "account_type"::"public"."account_type";--> statement-breakpoint

-- Convert status column to enum
ALTER TABLE "users" ALTER COLUMN "status" SET DEFAULT 'active'::"public"."status";--> statement-breakpoint
ALTER TABLE "users" ALTER COLUMN "status" SET DATA TYPE "public"."status" USING "status"::"public"."status";