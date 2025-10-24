CREATE TYPE "public"."moderation_status" AS ENUM('approved', 'flagged', 'rejected', 'review_pending');--> statement-breakpoint
CREATE TABLE "post_reports" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"post_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"reason" text NOT NULL,
	"description" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "post_reports_user_post_unq" UNIQUE("user_id","post_id")
);
--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "moderation_status" "moderation_status" DEFAULT 'approved' NOT NULL;--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "moderated_by" uuid;--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "moderated_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "flag_count" integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "flag_reasons" jsonb DEFAULT '[]'::jsonb;--> statement-breakpoint
ALTER TABLE "post_reports" ADD CONSTRAINT "post_reports_post_id_posts_id_fk" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "post_reports" ADD CONSTRAINT "post_reports_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "post_reports_post_id_idx" ON "post_reports" USING btree ("post_id");--> statement-breakpoint
CREATE INDEX "post_reports_user_id_idx" ON "post_reports" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "post_reports_created_at_idx" ON "post_reports" USING btree ("created_at");--> statement-breakpoint
ALTER TABLE "posts" ADD CONSTRAINT "posts_moderated_by_users_id_fk" FOREIGN KEY ("moderated_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "posts_moderation_status_idx" ON "posts" USING btree ("moderation_status");