ALTER TABLE "notifications" ADD COLUMN "status" text DEFAULT 'PENDING' NOT NULL;--> statement-breakpoint
ALTER TABLE "notifications" ADD COLUMN "delivery_channel" text;--> statement-breakpoint
ALTER TABLE "notifications" ADD COLUMN "retry_count" integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "notifications" ADD COLUMN "sent_at" timestamp with time zone;