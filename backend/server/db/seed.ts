import { drizzle } from 'drizzle-orm/postgres-js';
import { seed, reset } from 'drizzle-seed';
import { sql, notInArray } from 'drizzle-orm';
import postgres from 'postgres';
import * as schema from './schema';

const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
	throw new Error('DATABASE_URL environment variable is required');
}

const EXCLUDE_USERS = process.env.EXCLUDE_USERS?.split(',').map((email) => email.trim()) || [];

const SEED_USERS_COUNT = Number(process.env.SEED_USERS_COUNT) || 50;
const SEED_COLLECTIONS_COUNT = Number(process.env.SEED_COLLECTIONS_COUNT) || 30;
const SEED_QUIZZES_COUNT = Number(process.env.SEED_QUIZZES_COUNT) || 100;
const SEED_QUESTIONS_COUNT = Number(process.env.SEED_QUESTIONS_COUNT) || 500;
const SEED_QUIZ_SNAPSHOTS_COUNT = Number(process.env.SEED_QUIZ_SNAPSHOTS_COUNT) || 150;
const SEED_QUESTIONS_SNAPSHOTS_COUNT = Number(process.env.SEED_QUESTIONS_SNAPSHOTS_COUNT) || 750;
const SEED_GAME_SESSIONS_COUNT = Number(process.env.SEED_GAME_SESSIONS_COUNT) || 200;
const SEED_GAME_PARTICIPANTS_COUNT = Number(process.env.SEED_GAME_PARTICIPANTS_COUNT) || 1000;
const SEED_SAVED_QUIZZES_COUNT = Number(process.env.SEED_SAVED_QUIZZES_COUNT) || 300;
const SEED_POSTS_COUNT = Number(process.env.SEED_POSTS_COUNT) || 200;
const SEED_POST_LIKES_COUNT = Number(process.env.SEED_POST_LIKES_COUNT) || 500;
const SEED_COMMENTS_COUNT = Number(process.env.SEED_COMMENTS_COUNT) || 400;
const SEED_COMMENT_LIKES_COUNT = Number(process.env.SEED_COMMENT_LIKES_COUNT) || 300;
const SEED_FOLLOWS_COUNT = Number(process.env.SEED_FOLLOWS_COUNT) || 500;
const SEED_NOTIFICATIONS_COUNT = Number(process.env.SEED_NOTIFICATIONS_COUNT) || 1000;

const {
	users,
	collections,
	quizzes,
	questions,
	quizSnapshots,
	questionsSnapshots,
	gameSessions,
	gameSessionParticipants,
	savedQuizzes,
	posts,
	postLikes,
	comments,
	commentLikes,
	follows,
	notifications,
} = schema;

const seedSchema = {
	users,
	collections,
	quizzes,
	questions,
	quizSnapshots,
	questionsSnapshots,
	gameSessions,
	gameSessionParticipants,
	savedQuizzes,
	posts,
	postLikes,
	comments,
	commentLikes,
	follows,
	notifications,
};

const main = async () => {
	console.log('🌱 Starting database seeding...');

	const client = postgres(DATABASE_URL);
	const db = drizzle(client);

	if (EXCLUDE_USERS.length > 0) {
		console.log(`\n🔒 Protected users (will NOT be deleted):`);
		EXCLUDE_USERS.forEach((email) => console.log(`   - ${email}`));

		const excludedUsers = await db
			.select({ id: schema.users.id, email: schema.users.email })
			.from(schema.users)
			.where(sql`${schema.users.email} = ANY(${EXCLUDE_USERS})`);

		if (excludedUsers.length > 0) {
			console.log(`\n✅ Found ${excludedUsers.length} protected user(s) in database`);
			const excludedUserIds = excludedUsers.map((u) => u.id);

			console.log('🧹 Resetting database (excluding protected users and their data)...');
			
			await db.delete(schema.notifications).where(notInArray(schema.notifications.userId, excludedUserIds));
			await db.delete(schema.commentLikes).where(notInArray(schema.commentLikes.userId, excludedUserIds));
			await db.delete(schema.comments).where(notInArray(schema.comments.userId, excludedUserIds));
			await db.delete(schema.postLikes).where(notInArray(schema.postLikes.userId, excludedUserIds));
			await db.delete(schema.posts).where(notInArray(schema.posts.userId, excludedUserIds));
			await db.delete(schema.follows).where(
				sql`${schema.follows.followerId} != ALL(${excludedUserIds}) AND ${schema.follows.followingId} != ALL(${excludedUserIds})`
			);
			await db.delete(schema.savedQuizzes).where(notInArray(schema.savedQuizzes.userId, excludedUserIds));
			await db.delete(schema.gameSessionParticipants).where(
				sql`${schema.gameSessionParticipants.userId} IS NULL OR ${schema.gameSessionParticipants.userId} != ALL(${excludedUserIds})`
			);
			await db.delete(schema.gameSessions).where(notInArray(schema.gameSessions.hostId, excludedUserIds));
			await db.delete(schema.questionsSnapshots);
			await db.delete(schema.quizSnapshots);
			await db.delete(schema.questions);
			await db.delete(schema.quizzes).where(notInArray(schema.quizzes.userId, excludedUserIds));
			await db.delete(schema.collections).where(notInArray(schema.collections.userId, excludedUserIds));
			await db.delete(schema.users).where(notInArray(schema.users.id, excludedUserIds));

			console.log('✅ Database reset complete (protected users preserved)');
		} else {
			console.log(`\n⚠️  No protected users found in database, resetting everything...`);
			await reset(db, seedSchema);
			console.log('✅ Database reset complete');
		}
	} else {
		console.log('🧹 Resetting database...');
		await reset(db, seedSchema);
		console.log('✅ Database reset complete');
	}

	const categories = [
		'Science',
		'History',
		'Geography',
		'Mathematics',
		'Literature',
		'Technology',
		'Sports',
		'Music',
		'Art',
		'Business',
	];

	const questionTypes: string[] = [
		'multiple_choice',
		'true_false',
		'single_answer',
		'reorder',
		'type_answer',
		'drop_pin',
	];

	const accountTypes = ['student', 'teacher', 'professional'];

	const bios = [
		'Quiz enthusiast and educator',
		'Learning something new every day 📚',
		'Creating engaging educational content',
		'Passionate about knowledge sharing',
		'Making learning fun for everyone',
		'Teacher by day, quiz creator by night',
		'Building better learning experiences',
		'Education technology advocate',
	];

	const notificationTypes = ['like', 'comment', 'follow', 'quiz_share', 'game_invite'];

	const startTime = Date.now();
	console.log('\n📊 Seeding configuration:');
	console.log(`   Users: ${SEED_USERS_COUNT}`);
	console.log(`   Collections: ${SEED_COLLECTIONS_COUNT}`);
	console.log(`   Quizzes: ${SEED_QUIZZES_COUNT}`);
	console.log(`   Questions: ${SEED_QUESTIONS_COUNT}`);
	console.log(`   Quiz Snapshots: ${SEED_QUIZ_SNAPSHOTS_COUNT}`);
	console.log(`   Question Snapshots: ${SEED_QUESTIONS_SNAPSHOTS_COUNT}`);
	console.log(`   Game Sessions: ${SEED_GAME_SESSIONS_COUNT}`);
	console.log(`   Game Participants: ${SEED_GAME_PARTICIPANTS_COUNT}`);
	console.log(`   Saved Quizzes: ${SEED_SAVED_QUIZZES_COUNT}`);
	console.log(`   Posts: ${SEED_POSTS_COUNT}`);
	console.log(`   Post Likes: ${SEED_POST_LIKES_COUNT}`);
	console.log(`   Comments: ${SEED_COMMENTS_COUNT}`);
	console.log(`   Comment Likes: ${SEED_COMMENT_LIKES_COUNT}`);
	console.log(`   Follows: ${SEED_FOLLOWS_COUNT}`);
	console.log(`   Notifications: ${SEED_NOTIFICATIONS_COUNT}`);
	console.log('\n🚀 Starting seeding process...\n');

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

	const endTime = Date.now();
	const duration = ((endTime - startTime) / 1000).toFixed(2);

	console.log('\n✅ Database seeding completed successfully!');
	console.log(`\n📊 Summary:`);
	console.log(`   Total records: ${SEED_USERS_COUNT + SEED_COLLECTIONS_COUNT + SEED_QUIZZES_COUNT + SEED_QUESTIONS_COUNT + SEED_QUIZ_SNAPSHOTS_COUNT + SEED_QUESTIONS_SNAPSHOTS_COUNT + SEED_GAME_SESSIONS_COUNT + SEED_GAME_PARTICIPANTS_COUNT + SEED_SAVED_QUIZZES_COUNT + SEED_POSTS_COUNT + SEED_POST_LIKES_COUNT + SEED_COMMENTS_COUNT + SEED_COMMENT_LIKES_COUNT + SEED_FOLLOWS_COUNT + SEED_NOTIFICATIONS_COUNT}`);
	console.log(`   Time taken: ${duration}s`);
	console.log(`\n💡 Tip: Customize counts via environment variables (e.g., SEED_USERS_COUNT=100)`);

	await client.end();
};

main().catch((error) => {
	console.error('❌ Seeding failed:', error);
	process.exit(1);
});
