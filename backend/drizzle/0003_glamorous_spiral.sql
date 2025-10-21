CREATE TABLE "question_timings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"participant_id" uuid NOT NULL,
	"session_id" uuid NOT NULL,
	"question_snapshot_id" uuid NOT NULL,
	"server_start_time" timestamp with time zone NOT NULL,
	"deadline_time" timestamp with time zone NOT NULL,
	"submitted_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "question_timings_participant_question_unq" UNIQUE("participant_id","question_snapshot_id")
);
--> statement-breakpoint
DROP TABLE "user_question_timings" CASCADE;--> statement-breakpoint
ALTER TABLE "question_timings" ADD CONSTRAINT "question_timings_participant_id_game_session_participants_id_fk" FOREIGN KEY ("participant_id") REFERENCES "public"."game_session_participants"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "question_timings" ADD CONSTRAINT "question_timings_session_id_game_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."game_sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "question_timings" ADD CONSTRAINT "question_timings_question_snapshot_id_questions_snapshots_id_fk" FOREIGN KEY ("question_snapshot_id") REFERENCES "public"."questions_snapshots"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "question_timings_participant_session_idx" ON "question_timings" USING btree ("participant_id","session_id");--> statement-breakpoint
CREATE INDEX "question_timings_deadline_idx" ON "question_timings" USING btree ("deadline_time");