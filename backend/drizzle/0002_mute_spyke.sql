CREATE TYPE "public"."post_type" AS ENUM('text', 'image', 'quiz');--> statement-breakpoint
CREATE TABLE "post_answers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"post_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"answer" jsonb NOT NULL,
	"is_correct" boolean NOT NULL,
	"answered_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "post_type" "post_type" DEFAULT 'text' NOT NULL;--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "image_url" text;--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "question_type" "question_type";--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "question_text" text;--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "question_data" jsonb;--> statement-breakpoint
ALTER TABLE "posts" ADD COLUMN "answers_count" integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "post_answers" ADD CONSTRAINT "post_answers_post_id_posts_id_fk" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "post_answers" ADD CONSTRAINT "post_answers_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "post_answers_post_id_idx" ON "post_answers" USING btree ("post_id");--> statement-breakpoint
CREATE INDEX "post_answers_user_id_idx" ON "post_answers" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "post_answers_post_id_user_id_idx" ON "post_answers" USING btree ("post_id","user_id");--> statement-breakpoint
CREATE INDEX "posts_post_type_idx" ON "posts" USING btree ("post_type");