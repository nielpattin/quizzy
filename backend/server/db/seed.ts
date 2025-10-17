import { drizzle } from 'drizzle-orm/postgres-js';
import { reset } from 'drizzle-seed';
import { inArray } from 'drizzle-orm';
import postgres from 'postgres';
import * as schema from './schema';
import { EXCLUDE_USERS, calculateDerivedCounts } from './config-seed';
import { seedExcludedUsers } from './user-seed';
import { seedRegularUsers } from './other-seed';

const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
	throw new Error('DATABASE_URL environment variable is required');
}

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

const main = async () => {
	console.log('🌱 Starting database seeding...');

	const client = postgres(DATABASE_URL);
	const db = drizzle(client);

	// Calculate derived counts for excluded users
	let excludedUserIds: string[] = [];
	let excludedDerivedCounts = {
		collections: 0,
		quizzes: 0,
		questions: 0,
		gameSessions: 0,
		gameParticipants: 0,
		savedQuizzes: 0,
		posts: 0,
		follows: 0,
		notifications: 0,
	};

	if (EXCLUDE_USERS.length > 0) {
		const excludedUsers = await db
			.select({ id: schema.users.id, email: schema.users.email })
			.from(schema.users)
			.where(inArray(schema.users.email, EXCLUDE_USERS));

		if (excludedUsers.length > 0) {
			console.log(`🔒 Found ${excludedUsers.length} protected user(s)`);
			excludedUserIds = excludedUsers.map((u) => u.id);
			
			// Calculate derived counts for excluded users
			excludedDerivedCounts = calculateDerivedCounts(excludedUserIds);

			console.log('🧹 Resetting database (preserving protected users)...');
			
			// Use a simpler approach: delete everything, then re-insert excluded user data
			await reset(db, seedSchema);
			
			// Re-insert excluded users (they were deleted by reset)
			for (const user of excludedUsers) {
				await db.insert(schema.users).values({
					id: user.id,
					email: user.email,
				}).onConflictDoNothing();
			}
		} else {
			console.log('⚠️  No protected users found, resetting everything...');
			await reset(db, seedSchema);
		}
	} else {
		console.log('🧹 Resetting database...');
		await reset(db, seedSchema);
	}

	const startTime = Date.now();
	
	// Import regular user counts for display
	const {
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
	} = await import('./config-seed');
	
	const totalRegularUsers = SEED_USERS_COUNT + (excludedUserIds.length > 0 ? excludedUserIds.length : 0);
	console.log(`\n📊 Seeding ${totalRegularUsers} users (${excludedUserIds.length > 0 ? excludedUserIds.length + ' excluded' : 'all regular'})...`);
	console.log('\n🚀 Starting seeding process...\n');

	// Generate data for regular users first
	await seedRegularUsers(db);

	// Generate guaranteed data for excluded users
	if (excludedUserIds.length > 0) {
		await seedExcludedUsers(db, excludedUserIds);
	}

	const endTime = Date.now();
	const duration = ((endTime - startTime) / 1000).toFixed(2);
	
	console.log('\n✅ Database seeding completed successfully!');
	
	if (excludedUserIds.length > 0) {
		const excludedTotal = excludedUserIds.length + excludedDerivedCounts.collections + excludedDerivedCounts.quizzes + excludedDerivedCounts.questions + excludedDerivedCounts.gameSessions + excludedDerivedCounts.gameParticipants + excludedDerivedCounts.savedQuizzes + excludedDerivedCounts.posts + excludedDerivedCounts.follows + excludedDerivedCounts.notifications;
		const regularTotal = SEED_USERS_COUNT + SEED_COLLECTIONS_COUNT + SEED_QUIZZES_COUNT + SEED_QUESTIONS_COUNT + SEED_QUIZ_SNAPSHOTS_COUNT + SEED_QUESTIONS_SNAPSHOTS_COUNT + SEED_GAME_SESSIONS_COUNT + SEED_GAME_PARTICIPANTS_COUNT + SEED_SAVED_QUIZZES_COUNT + SEED_POSTS_COUNT + SEED_POST_LIKES_COUNT + SEED_COMMENTS_COUNT + SEED_COMMENT_LIKES_COUNT + SEED_FOLLOWS_COUNT + SEED_NOTIFICATIONS_COUNT;
		
		console.log(`\n📊 Summary: ${excludedTotal + regularTotal} records (${excludedTotal} excluded + ${regularTotal} regular) in ${duration}s`);
	} else {
		const totalRecords = SEED_USERS_COUNT + SEED_COLLECTIONS_COUNT + SEED_QUIZZES_COUNT + SEED_QUESTIONS_COUNT + SEED_QUIZ_SNAPSHOTS_COUNT + SEED_QUESTIONS_SNAPSHOTS_COUNT + SEED_GAME_SESSIONS_COUNT + SEED_GAME_PARTICIPANTS_COUNT + SEED_SAVED_QUIZZES_COUNT + SEED_POSTS_COUNT + SEED_POST_LIKES_COUNT + SEED_COMMENTS_COUNT + SEED_COMMENT_LIKES_COUNT + SEED_FOLLOWS_COUNT + SEED_NOTIFICATIONS_COUNT;
		console.log(`\n📊 Summary: ${totalRecords} records in ${duration}s`);
	}
	
	console.log('\n💡 Tip: Customize counts via environment variables (e.g., SEED_USERS_COUNT=100, SEED_EXCLUDED_QUIZZES_PER_USER=15)');

	await client.end();
};

main().catch((error) => {
	console.error('❌ Seeding failed:', error);
	process.exit(1);
});