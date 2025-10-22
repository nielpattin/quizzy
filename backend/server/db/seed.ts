import { drizzle } from 'drizzle-orm/postgres-js';
import { reset } from 'drizzle-seed';
import { inArray, sql } from 'drizzle-orm';
import postgres from 'postgres';
import * as schema from './schema';
import { EXCLUDE_USERS, calculateDerivedCounts } from './config-seed';
import { seedExcludedUsers } from './user-seed';
import { seedRegularUsers } from './other-seed';
import { seedFixedUsers, seedFixedUsersData } from './fixed-users';

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

	// Suppress NOTICE messages
	await db.execute(sql`SET client_min_messages TO WARNING;`);

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
			.select()
			.from(schema.users)
			.where(inArray(schema.users.email, EXCLUDE_USERS));

		if (excludedUsers.length > 0) {
			console.log(`🔒 Found ${excludedUsers.length} protected user(s)`);
			excludedUserIds = excludedUsers.map((u) => u.id);
			
			// Backup all data for excluded users
			console.log('💾 Backing up protected user data...');
			const excludedCollections = await db.select().from(schema.collections).where(inArray(schema.collections.userId, excludedUserIds));
			const excludedQuizzes = await db.select().from(schema.quizzes).where(inArray(schema.quizzes.userId, excludedUserIds));
			const excludedQuizIds = excludedQuizzes.map(q => q.id);
			const excludedQuestions = excludedQuizIds.length > 0 ? await db.select().from(schema.questions).where(inArray(schema.questions.quizId, excludedQuizIds)) : [];
			const excludedSnapshots = excludedQuizIds.length > 0 ? await db.select().from(schema.quizSnapshots).where(inArray(schema.quizSnapshots.quizId, excludedQuizIds)) : [];
			const excludedSnapshotIds = excludedSnapshots.map(s => s.id);
			const excludedSnapshotQuestions = excludedSnapshotIds.length > 0 ? await db.select().from(schema.questionsSnapshots).where(inArray(schema.questionsSnapshots.snapshotId, excludedSnapshotIds)) : [];
			const excludedSessions = await db.select().from(schema.gameSessions).where(inArray(schema.gameSessions.hostId, excludedUserIds));
			const excludedSessionIds = excludedSessions.map(s => s.id);
			const excludedParticipants = excludedSessionIds.length > 0 ? await db.select().from(schema.gameSessionParticipants).where(inArray(schema.gameSessionParticipants.sessionId, excludedSessionIds)) : [];
			const excludedSavedQuizzes = await db.select().from(schema.savedQuizzes).where(inArray(schema.savedQuizzes.userId, excludedUserIds));
			const excludedPosts = await db.select().from(schema.posts).where(inArray(schema.posts.userId, excludedUserIds));
			const excludedPostIds = excludedPosts.map(p => p.id);
			const excludedPostLikes = excludedPostIds.length > 0 ? await db.select().from(schema.postLikes).where(inArray(schema.postLikes.postId, excludedPostIds)) : [];
			const excludedComments = excludedPostIds.length > 0 ? await db.select().from(schema.comments).where(inArray(schema.comments.postId, excludedPostIds)) : [];
			const excludedCommentIds = excludedComments.map(c => c.id);
			const excludedCommentLikes = excludedCommentIds.length > 0 ? await db.select().from(schema.commentLikes).where(inArray(schema.commentLikes.commentId, excludedCommentIds)) : [];
			const excludedFollows = await db.select().from(schema.follows).where(inArray(schema.follows.followerId, excludedUserIds));
			const excludedNotifications = await db.select().from(schema.notifications).where(inArray(schema.notifications.userId, excludedUserIds));
			
			// Calculate derived counts for excluded users
			excludedDerivedCounts = {
				collections: excludedCollections.length,
				quizzes: excludedQuizzes.length,
				questions: excludedQuestions.length,
				gameSessions: excludedSessions.length,
				gameParticipants: excludedParticipants.length,
				savedQuizzes: excludedSavedQuizzes.length,
				posts: excludedPosts.length,
				follows: excludedFollows.length,
				notifications: excludedNotifications.length,
			};

			console.log('🧹 Resetting database (preserving protected users)...');
			await reset(db, seedSchema);
			
			// Restore all excluded user data
			console.log('♻️  Restoring protected user data...');
			if (excludedUsers.length > 0) await db.insert(schema.users).values(excludedUsers).onConflictDoNothing();
			if (excludedCollections.length > 0) await db.insert(schema.collections).values(excludedCollections).onConflictDoNothing();
			if (excludedQuizzes.length > 0) await db.insert(schema.quizzes).values(excludedQuizzes).onConflictDoNothing();
			if (excludedQuestions.length > 0) await db.insert(schema.questions).values(excludedQuestions).onConflictDoNothing();
			if (excludedSnapshots.length > 0) await db.insert(schema.quizSnapshots).values(excludedSnapshots).onConflictDoNothing();
			if (excludedSnapshotQuestions.length > 0) await db.insert(schema.questionsSnapshots).values(excludedSnapshotQuestions).onConflictDoNothing();
			if (excludedSessions.length > 0) await db.insert(schema.gameSessions).values(excludedSessions).onConflictDoNothing();
			if (excludedParticipants.length > 0) await db.insert(schema.gameSessionParticipants).values(excludedParticipants).onConflictDoNothing();
			if (excludedSavedQuizzes.length > 0) await db.insert(schema.savedQuizzes).values(excludedSavedQuizzes).onConflictDoNothing();
			if (excludedPosts.length > 0) await db.insert(schema.posts).values(excludedPosts).onConflictDoNothing();
			if (excludedPostLikes.length > 0) await db.insert(schema.postLikes).values(excludedPostLikes).onConflictDoNothing();
			if (excludedComments.length > 0) await db.insert(schema.comments).values(excludedComments).onConflictDoNothing();
			if (excludedCommentLikes.length > 0) await db.insert(schema.commentLikes).values(excludedCommentLikes).onConflictDoNothing();
			if (excludedFollows.length > 0) await db.insert(schema.follows).values(excludedFollows).onConflictDoNothing();
			if (excludedNotifications.length > 0) await db.insert(schema.notifications).values(excludedNotifications).onConflictDoNothing();
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

	// Seed deterministic fixed users
	await seedFixedUsers(db);

	// Upload seed images to MinIO before generating posts
	console.log('\n📤 Uploading seed images to MinIO...');
	const fixedUsers = await db.select().from(schema.users).limit(1);
	const seedImageOwner = fixedUsers[0]?.id || (excludedUserIds.length > 0 ? excludedUserIds[0] : null);

	let seedImageUrls: { posts: string[], quizzes: string[] } = { posts: [], quizzes: [] };

	if (seedImageOwner) {
		const { uploadAllSeedImages } = await import('./config-seed');
		seedImageUrls = await uploadAllSeedImages(db, seedImageOwner);
	} else {
		console.warn('⚠️  No users available for image ownership - skipping image upload');
	}

	// Generate data for random users
	await seedRegularUsers(db, seedImageUrls);

	// Generate guaranteed data for excluded users
	if (excludedUserIds.length > 0) {
		await seedExcludedUsers(db, excludedUserIds, seedImageUrls);
	}

	// Seed collections and saved quizzes for fixed users (after quizzes exist)
	await seedFixedUsersData(db);

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