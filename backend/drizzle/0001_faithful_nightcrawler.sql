CREATE TYPE "public"."session_status" AS ENUM('waiting', 'ongoing', 'ended', 'abandoned');--> statement-breakpoint
ALTER TABLE "game_sessions" ADD COLUMN "status" "session_status" DEFAULT 'ongoing' NOT NULL;--> statement-breakpoint
CREATE INDEX "game_sessions_status_idx" ON "game_sessions" USING btree ("status");