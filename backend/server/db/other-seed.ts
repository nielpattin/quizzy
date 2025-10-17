import { seed } from 'drizzle-seed';
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
	await seed(db, seedSchema, { count: 10 }).refine((f) => ({
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
				title: f.loremIpsum({ sentencesCount: 1 }),
				description: f.loremIpsum({ sentencesCount: 3 }),
				quizCount: f.int({ minValue: 0, maxValue: 20 }),
				isPublic: f.boolean(),
			},
		},
		quizzes: {
			count: SEED_QUIZZES_COUNT,
			columns: {
				title: f.loremIpsum({ sentencesCount: 1 }),
				description: f.loremIpsum({ sentencesCount: 2 }),
				category: f.valuesFromArray({ values: categories }),
				questionCount: f.int({ minValue: 5, maxValue: 50 }),
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
				questionText: f.loremIpsum({ sentencesCount: 1 }),
				data: f.json(),
				orderIndex: f.int({ minValue: 0, maxValue: 49 }),
			},
		},
		quizSnapshots: {
			count: SEED_QUIZ_SNAPSHOTS_COUNT,
			columns: {
				version: f.int({ minValue: 1, maxValue: 5 }),
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
				text: f.loremIpsum({ sentencesCount: 3 }),
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
				title: f.loremIpsum({ sentencesCount: 1 }),
				subtitle: f.loremIpsum({ sentencesCount: 1 }),
				isUnread: f.boolean(),
			},
		},
	}));

	console.log('✅ Regular user data generation completed');
};