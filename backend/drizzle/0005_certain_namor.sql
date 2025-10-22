-- Convert columns to text temporarily
ALTER TABLE "posts" ALTER COLUMN "question_type" SET DATA TYPE text;--> statement-breakpoint
ALTER TABLE "questions" ALTER COLUMN "type" SET DATA TYPE text;--> statement-breakpoint
ALTER TABLE "questions_snapshots" ALTER COLUMN "type" SET DATA TYPE text;--> statement-breakpoint

-- Update existing data to new enum values
UPDATE "posts" SET "question_type" = 'single_choice' WHERE "question_type" = 'multiple_choice';--> statement-breakpoint
UPDATE "posts" SET "question_type" = 'checkbox' WHERE "question_type" = 'single_answer';--> statement-breakpoint
UPDATE "questions" SET "type" = 'single_choice' WHERE "type" = 'multiple_choice';--> statement-breakpoint
UPDATE "questions" SET "type" = 'checkbox' WHERE "type" = 'single_answer';--> statement-breakpoint
UPDATE "questions_snapshots" SET "type" = 'single_choice' WHERE "type" = 'multiple_choice';--> statement-breakpoint
UPDATE "questions_snapshots" SET "type" = 'checkbox' WHERE "type" = 'single_answer';--> statement-breakpoint

-- Drop old enum type
DROP TYPE "public"."question_type";--> statement-breakpoint

-- Create new enum type with updated values
CREATE TYPE "public"."question_type" AS ENUM('single_choice', 'checkbox', 'true_false', 'type_answer', 'reorder', 'drop_pin');--> statement-breakpoint

-- Convert columns back to enum type
ALTER TABLE "posts" ALTER COLUMN "question_type" SET DATA TYPE "public"."question_type" USING "question_type"::"public"."question_type";--> statement-breakpoint
ALTER TABLE "questions" ALTER COLUMN "type" SET DATA TYPE "public"."question_type" USING "type"::"public"."question_type";--> statement-breakpoint
ALTER TABLE "questions_snapshots" ALTER COLUMN "type" SET DATA TYPE "public"."question_type" USING "type"::"public"."question_type";