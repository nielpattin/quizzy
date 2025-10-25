import { drizzle } from 'drizzle-orm/postgres-js';
import { reset } from 'drizzle-seed';
import { sql } from 'drizzle-orm';
import postgres from 'postgres';
import * as schema from './schema';
import { SEED_USERS, SEED_USERS_COUNT, getRegularUserCounts } from './seed-data';
import {
	uploadAllSeedImages,
	seedFixedUsers,
	seedFixedUsersData,
	seedSpecificUsers,
	seedRegularUsers,
} from './seed-functions';

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

	await db.execute(sql`SET client_min_messages TO WARNING;`);
	await reset(db, seedSchema);

	const { cleanMinIOBuckets } = await import('../../scripts/setup-minio');
	await cleanMinIOBuckets();

	const startTime = Date.now();

	await seedFixedUsers(db);
	await seedSpecificUsers(db);

	const fixedUsers = await db.select().from(schema.users).limit(1);
	const seedImageOwner = fixedUsers[0]?.id;

	let seedImageUrls: { posts: string[]; quizzes: string[]; profiles: string[] } = { posts: [], quizzes: [], profiles: [] };
	if (seedImageOwner) {
		seedImageUrls = await uploadAllSeedImages(db, seedImageOwner);
	}

	const totalUsers = SEED_USERS_COUNT + SEED_USERS.length;
	const regularCounts = getRegularUserCounts(totalUsers);

	await seedRegularUsers(db, seedImageUrls);
	await seedFixedUsersData(db);

	const endTime = Date.now();
	const duration = ((endTime - startTime) / 1000).toFixed(2);

	const totalRecords = Object.values(regularCounts).reduce((a, b) => a + b, 0);
	console.log(`✅ Seeded ${totalRecords} records in ${duration}s`);

	await client.end();
};

main().catch((error) => {
	console.error('❌ Seeding failed:', error);
	process.exit(1);
});
