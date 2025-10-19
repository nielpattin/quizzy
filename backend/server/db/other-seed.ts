import { seed } from 'drizzle-seed';
import { eq } from 'drizzle-orm';
import * as schema from './schema';
import {
	SEED_USERS_COUNT,
	SEED_COLLECTIONS_COUNT,
	SEED_QUIZZES_COUNT,
	SEED_QUESTIONS_COUNT,
	SEED_QUIZ_SNAPSHOTS_COUNT,
	SEED_QUESTIONS_SNAPSHOTS_COUNT,
	SEED_GAME_SESSIONS_COUNT,
	SEED_GAME_PARTICIPANTS_COUNT,
	SEED_SAVED_QUIZZES_COUNT,
	SEED_POSTS_COUNT,
	SEED_POST_LIKES_COUNT,
	SEED_COMMENTS_COUNT,
	SEED_COMMENT_LIKES_COUNT,
	SEED_FOLLOWS_COUNT,
	SEED_NOTIFICATIONS_COUNT,
	categories,
	questionTypes,
	accountTypes,
	bios,
	notificationTypes,
	generateQuizTitle,
	generateQuizDescription,
	generateQuestionText,
	generateQuestionData,
} from './config-seed';

const seedSchema = {
	users: schema.users,
	collections: schema.collections,
	quizzes: schema.quizzes,
	questions: schema.questions,
	quizSnapshots: schema.quizSnapshots,
	questionsSnapshots: schema.questionsSnapshots,
	gameSessions: schema.gameSessions,
	gameSessionParticipants: schema.gameSessionParticipants,
	savedQuizzes: schema.savedQuizzes,
	posts: schema.posts,
	postLikes: schema.postLikes,
	comments: schema.comments,
	commentLikes: schema.commentLikes,
	follows: schema.follows,
	notifications: schema.notifications,
};

export const seedRegularUsers = async (db: any) => {
	const seeded = await seed(db, seedSchema, { count: 10 }).refine((f) => ({
		users: {
			count: SEED_USERS_COUNT,
			columns: {
				fullName: f.fullName(),
				email: f.email(),
				username: f.string({ isUnique: true }),
				dob: f.date({ minDate: '1990-01-01', maxDate: '2005-12-31' }),
				bio: f.valuesFromArray({ values: bios }),
				accountType: f.valuesFromArray({ values: accountTypes }),
				isSetupComplete: f.boolean(),
				followersCount: f.int({ minValue: 0, maxValue: 1000 }),
				followingCount: f.int({ minValue: 0, maxValue: 500 }),
			},
		},
		collections: {
			count: SEED_COLLECTIONS_COUNT,
			columns: {
				title: f.valuesFromArray({ values: categories.map((c) => `${c} Study Pack`) }),
				description: f.valuesFromArray({ values: categories.map((c) => `Curated ${c} materials and practice sets`) }),
				quizCount: f.int({ minValue: 0, maxValue: 20 }),
				isPublic: f.boolean(),
			},
		},
		quizzes: {
			count: SEED_QUIZZES_COUNT,
			columns: {
				// placeholders; will be replaced in post-processing with category-aware values
				title: f.loremIpsum({ sentencesCount: 1 }),
				description: f.loremIpsum({ sentencesCount: 2 }),
				category: f.valuesFromArray({ values: categories }),
				questionCount: f.int({ minValue: 5, maxValue: 30 }),
				playCount: f.int({ minValue: 0, maxValue: 5000 }),
				favoriteCount: f.int({ minValue: 0, maxValue: 500 }),
				shareCount: f.int({ minValue: 0, maxValue: 200 }),
				isPublic: f.boolean(),
				questionsVisible: f.boolean(),
				isDeleted: f.boolean(),
				version: f.int({ minValue: 1, maxValue: 5 }),
			},
		},
		questions: {
			count: SEED_QUESTIONS_COUNT,
			columns: {
				type: f.valuesFromArray({ values: questionTypes }),
				// placeholders; will be updated in post-processing
				questionText: f.loremIpsum({ sentencesCount: 1 }),
				data: f.json(),
				orderIndex: f.int({ minValue: 0, maxValue: 49 }),
			},
		},
		quizSnapshots: {
			count: SEED_QUIZ_SNAPSHOTS_COUNT,
			columns: {
				version: f.int({ minValue: 1, maxValue: 5 }),
				// placeholders; will be updated post
				title: f.loremIpsum({ sentencesCount: 1 }),
				description: f.loremIpsum({ sentencesCount: 2 }),
				category: f.valuesFromArray({ values: categories }),
				questionCount: f.int({ minValue: 5, maxValue: 50 }),
			},
		},
		questionsSnapshots: {
			count: SEED_QUESTIONS_SNAPSHOTS_COUNT,
			columns: {
				type: f.valuesFromArray({ values: questionTypes }),
				// placeholders; will be updated post
				questionText: f.loremIpsum({ sentencesCount: 1 }),
				data: f.json(),
				orderIndex: f.int({ minValue: 0, maxValue: 49 }),
			},
		},
		gameSessions: {
			count: SEED_GAME_SESSIONS_COUNT,
			columns: {
				title: f.loremIpsum({ sentencesCount: 1 }),
				estimatedMinutes: f.int({ minValue: 5, maxValue: 60 }),
				isLive: f.boolean(),
				joinedCount: f.int({ minValue: 0, maxValue: 100 }),
				code: f.string({ isUnique: true }),
				quizVersion: f.int({ minValue: 1, maxValue: 5 }),
			},
		},
		gameSessionParticipants: {
			count: SEED_GAME_PARTICIPANTS_COUNT,
			columns: {
				score: f.int({ minValue: 0, maxValue: 10000 }),
				rank: f.int({ minValue: 1, maxValue: 100 }),
			},
		},
		savedQuizzes: {
			count: SEED_SAVED_QUIZZES_COUNT,
		},
		posts: {
			count: SEED_POSTS_COUNT,
			columns: {
				text: f.valuesFromArray({ values: categories.map((c) => `Sharing a new ${c} quiz – feedback welcome!`) }),
				likesCount: f.int({ minValue: 0, maxValue: 500 }),
				commentsCount: f.int({ minValue: 0, maxValue: 100 }),
			},
		},
		postLikes: {
			count: SEED_POST_LIKES_COUNT,
		},
		comments: {
			count: SEED_COMMENTS_COUNT,
			columns: {
				content: f.loremIpsum({ sentencesCount: 2 }),
				likesCount: f.int({ minValue: 0, maxValue: 50 }),
			},
		},
		commentLikes: {
			count: SEED_COMMENT_LIKES_COUNT,
		},
		follows: {
			count: SEED_FOLLOWS_COUNT,
		},
		notifications: {
			count: SEED_NOTIFICATIONS_COUNT,
			columns: {
				type: f.valuesFromArray({ values: notificationTypes }),
				isUnread: f.boolean(),
			},
		},
	}));

	// Post-process: enrich quizzes and questions with category-aware titles and texts
	// Fetch quizzes just inserted and update title/description if missing
	const quizzes = await db.select().from(schema.quizzes);
	for (const q of quizzes) {
		const title = generateQuizTitle(q.category ?? 'General');
		const description = generateQuizDescription(q.category ?? 'General');
		await db.update(schema.quizzes)
			.set({ title, description })
			.where(eq(schema.quizzes.id, q.id));
	}

	// Populate questions with questionText and data based on their quiz category and type
	const questions = await db.select({
		id: schema.questions.id,
		quizId: schema.questions.quizId,
		type: schema.questions.type,
		orderIndex: schema.questions.orderIndex,
	}).from(schema.questions);

	// Map quizId -> category
	const quizMap = new Map<string, { category: string | null }>();
	for (const q of quizzes) quizMap.set(q.id, { category: q.category ?? null });

	for (const qs of questions) {
		const meta = quizMap.get(qs.quizId);
		const questionText = generateQuestionText(meta?.category ?? null, qs.type as any, qs.orderIndex);
		const data = generateQuestionData(qs.type as any);
		await db.update(schema.questions)
			.set({ questionText, data })
			.where(eq(schema.questions.id, qs.id));
	}

	// Do similar for quizSnapshots and questionsSnapshots
	const quizSnapshots = await db.select().from(schema.quizSnapshots);
	for (const s of quizSnapshots) {
		const title = generateQuizTitle(s.category ?? 'General');
		const description = generateQuizDescription(s.category ?? 'General');
		await db.update(schema.quizSnapshots)
			.set({ title, description })
			.where(eq(schema.quizSnapshots.id, s.id));
	}
	const questionSnapshots = await db.select({
		id: schema.questionsSnapshots.id,
		snapshotId: schema.questionsSnapshots.snapshotId,
		type: schema.questionsSnapshots.type,
		orderIndex: schema.questionsSnapshots.orderIndex,
	}).from(schema.questionsSnapshots);
	const snapMap = new Map<string, { category: string | null }>();
	for (const s of quizSnapshots) snapMap.set(s.id, { category: s.category ?? null });
	for (const qs of questionSnapshots) {
		const meta = snapMap.get(qs.snapshotId);
		const questionText = generateQuestionText(meta?.category ?? null, qs.type as any, qs.orderIndex);
		const data = generateQuestionData(qs.type as any);
		await db.update(schema.questionsSnapshots)
			.set({ questionText, data })
			.where(eq(schema.questionsSnapshots.id, qs.id));
	}

	console.log('✅ Regular user data generation completed');
};