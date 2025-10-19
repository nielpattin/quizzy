CREATE TABLE "user_question_timings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"question_id" uuid NOT NULL,
	"session_id" uuid NOT NULL,
	"server_start_time" timestamp with time zone NOT NULL,
	"deadline_time" timestamp with time zone NOT NULL,
	"submitted_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "user_question_timings" ADD CONSTRAINT "user_question_timings_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_question_timings" ADD CONSTRAINT "user_question_timings_question_id_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_question_timings" ADD CONSTRAINT "user_question_timings_session_id_game_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "user_question_timings_user_session_idx" ON "user_question_timings" USING btree ("user_id","session_id");--> statement-breakpoint
CREATE INDEX "user_question_timings_deadline_idx" ON "user_question_timings" USING btree ("deadline_time");