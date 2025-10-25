import { seed } from 'drizzle-seed';
import { eq, desc } from 'drizzle-orm';
import * as schema from './schema';
import { getS3File, BUCKETS, type BucketName } from '../lib/s3';
import { supabaseAdmin } from '../lib/supabase';
import * as path from 'path';
import * as fs from 'fs/promises';
import {
	SEED_USERS,
	SEED_USERS_COUNT,
	SEED_COMMENTS_COUNT_PER_POST,
	categories,
	questionTypes,
	accountTypes,
	bios,
	notificationTypes,
	generateQuizTitle,
	generateQuizDescription,
	generateQuestionText,
	generateQuestionData,
	type SeedImageUrls,
	FIXED_USERS,
	FIXED_USER_COLLECTIONS,
	getRegularUserCounts,
} from './seed-data';

export const uploadSeedImage = async (
	db: any,
	filepath: string,
	userId: string,
	bucket: BucketName = BUCKETS.QUIZZES,
): Promise<string | null> => {
	try {
		const filename = `seed-${Date.now()}-${path.basename(filepath)}`;
		const file = Bun.file(filepath);
		const buffer = Buffer.from(await file.arrayBuffer());
		const mimeType = 'image/jpeg';

		const s3File = getS3File(filename, bucket);
		await s3File.write(buffer, { type: mimeType });

		const [image] = await db
			.insert(schema.images)
			.values({
				userId,
				filename,
				originalName: path.basename(filepath),
				mimeType,
				size: buffer.byteLength,
				bucket,
			})
			.returning();

		const url = s3File.presign({ expiresIn: 24 * 60 * 60 });
		return url;
	} catch (error) {
		console.error(`  ❌ Failed to upload ${path.basename(filepath)}:`, error);
		return null;
	}
};

export const uploadAllSeedImages = async (
	db: any,
	seedUserId: string,
): Promise<SeedImageUrls> => {
	const seedImagesDir = path.join(__dirname, 'seed-images');
	const postsDir = path.join(seedImagesDir, 'posts');
	const quizzesDir = path.join(seedImagesDir, 'quizzes');
	const profilesDir = path.join(seedImagesDir, 'profiles');

	const postUrls: string[] = [];
	const quizUrls: string[] = [];
	const profileUrls: string[] = [];

	console.log('📤 Uploading seed images to MinIO...');

	try {
		await fs.access(postsDir);
	} catch {
		console.warn('⚠️  Posts directory not found - run "bun run db:image" first');
		return { posts: [], quizzes: [], profiles: [] };
	}

	const postFiles = await fs.readdir(postsDir);
	const postJpgs = postFiles.filter((f) => f.endsWith('.jpg') || f.endsWith('.jpeg'));

	console.log(`  📂 Uploading ${postJpgs.length} post images...`);
	for (const file of postJpgs) {
		const url = await uploadSeedImage(db, path.join(postsDir, file), seedUserId, BUCKETS.POSTS);
		if (url) postUrls.push(url);
	}
	console.log(`  ✅ Uploaded ${postUrls.length} post images`);

	try {
		await fs.access(quizzesDir);
		const quizFiles = await fs.readdir(quizzesDir);
		const quizJpgs = quizFiles.filter((f) => f.endsWith('.jpg') || f.endsWith('.jpeg'));

		console.log(`  📂 Uploading ${quizJpgs.length} quiz images...`);
		for (const file of quizJpgs) {
			const url = await uploadSeedImage(db, path.join(quizzesDir, file), seedUserId, BUCKETS.QUIZZES);
			if (url) quizUrls.push(url);
		}
		console.log(`  ✅ Uploaded ${quizUrls.length} quiz images`);
	} catch {
		console.warn('⚠️  Quizzes directory not found');
	}

	try {
		await fs.access(profilesDir);
		const profileFiles = await fs.readdir(profilesDir);
		const profileJpgs = profileFiles.filter((f) => f.endsWith('.jpg') || f.endsWith('.jpeg'));

		console.log(`  📂 Uploading ${profileJpgs.length} profile images...`);
		for (const file of profileJpgs) {
			const url = await uploadSeedImage(db, path.join(profilesDir, file), seedUserId, BUCKETS.PROFILES);
			if (url) profileUrls.push(url);
		}
		console.log(`  ✅ Uploaded ${profileUrls.length} profile images`);
	} catch {
		console.warn('⚠️  Profiles directory not found');
	}

	console.log(`✅ Uploaded ${postUrls.length} post images, ${quizUrls.length} quiz images, and ${profileUrls.length} profile images`);

	return { posts: postUrls, quizzes: quizUrls, profiles: profileUrls };
};

export const seedFixedUsers = async (db: any) => {
	for (const u of FIXED_USERS) {
		await db
			.insert(schema.users)
			.values({
				email: u.email,
				fullName: u.fullName,
				username: u.username,
				bio: u.bio,
				accountType: u.accountType ?? 'user',
				isSetupComplete: u.isSetupComplete ?? true,
				profilePictureUrl: u.profilePictureUrl,
			})
			.onConflictDoNothing({ target: schema.users.email });
	}
};

export const seedFixedUsersData = async (db: any) => {
	console.log('🔧 Seeding collections and saved quizzes for fixed users...');

	for (const fixedUserConfig of FIXED_USER_COLLECTIONS) {
		const [user] = await db.select().from(schema.users).where(eq(schema.users.email, fixedUserConfig.email));

		if (!user) {
			console.warn(`⚠️  Fixed user ${fixedUserConfig.email} not found, skipping`);
			continue;
		}

		for (const collectionData of fixedUserConfig.collections) {
			const [newCollection] = await db
				.insert(schema.collections)
				.values({
					userId: user.id,
					title: collectionData.title,
					description: collectionData.description,
					quizCount: 0,
					isPublic: true,
				})
				.returning();

			const availableQuizzes = await db
				.select()
				.from(schema.quizzes)
				.where(eq(schema.quizzes.isDeleted, false))
				.limit(3);

			let addedCount = 0;
			for (const quiz of availableQuizzes) {
				await db.update(schema.quizzes).set({ collectionId: newCollection.id }).where(eq(schema.quizzes.id, quiz.id));
				addedCount++;
			}

			await db.update(schema.collections).set({ quizCount: addedCount }).where(eq(schema.collections.id, newCollection.id));
		}

		const availableQuizzes = await db
			.select()
			.from(schema.quizzes)
			.where(eq(schema.quizzes.isDeleted, false))
			.orderBy(desc(schema.quizzes.createdAt))
			.limit(8);

		for (const quiz of availableQuizzes) {
			await db
				.insert(schema.favoriteQuizzes)
				.values({ userId: user.id, quizId: quiz.id })
				.onConflictDoNothing();
		}
	}

	console.log('✅ Fixed users collections and favorite quizzes seeded');
};

export const seedSpecificUsers = async (db: any) => {
	if (SEED_USERS.length === 0) {
		return;
	}

	console.log(`\n👤 Creating ${SEED_USERS.length} specific seed users...`);

	if (!supabaseAdmin) {
		console.error('❌ Supabase Admin client not configured. Set SUPABASE_SERVICE_ROLE_KEY in .env');
		console.log('⚠️  Skipping SEED_USERS - they must exist in Supabase first');
		return;
	}

	// Fetch all Supabase users to find matching emails
	console.log('🔍 Fetching users from Supabase...');
	const { data: supabaseUsers, error } = await supabaseAdmin.auth.admin.listUsers();

	if (error) {
		console.error('❌ Failed to fetch Supabase users:', error);
		console.log('⚠️  Skipping SEED_USERS');
		return;
	}

	console.log(`📋 Found ${supabaseUsers.users.length} users in Supabase`);

	// Create a map of email -> Supabase UID
	const emailToUid = new Map<string, string>();
	for (const supabaseUser of supabaseUsers.users) {
		if (supabaseUser.email) {
			emailToUid.set(supabaseUser.email.toLowerCase(), supabaseUser.id);
		}
	}

	// Insert users with their actual Supabase UIDs
	for (const email of SEED_USERS) {
		const supabaseUid = emailToUid.get(email.toLowerCase());

		if (!supabaseUid) {
			console.log(`  ⚠️  User ${email} not found in Supabase - skipping`);
			continue;
		}

		const randomYear = 1990 + Math.floor(Math.random() * 15);
		const randomMonth = Math.floor(Math.random() * 12);
		const randomDay = Math.floor(Math.random() * 28) + 1;
		const dob = `${randomYear}-${String(randomMonth + 1).padStart(2, '0')}-${String(randomDay).padStart(2, '0')}`;

		const user = {
			id: supabaseUid, // Use actual Supabase UID
			email,
			fullName: `User ${email.split('@')[0]}`,
			username: email.split('@')[0].replace(/[^a-zA-Z0-9]/g, '_'),
			dob,
			bio: bios[Math.floor(Math.random() * bios.length)],
			accountType: accountTypes[Math.floor(Math.random() * accountTypes.length)] as any,
			isSetupComplete: true,
			followersCount: 0,
			followingCount: 0,
		};

		await db.insert(schema.users).values(user).onConflictDoNothing();
		console.log(`  ✅ Created user: ${email} (UID: ${supabaseUid})`);
	}

	console.log(`✅ Seed users created with actual Supabase UIDs\n`);
};

const seedSchemaDef = {
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
	follows: schema.follows,
	notifications: schema.notifications,
};

export const seedRegularUsers = async (db: any, seedImageUrls?: SeedImageUrls) => {
	const counts = getRegularUserCounts(SEED_USERS_COUNT);

	await seed(db, seedSchemaDef, { count: 10 }).refine((f) => ({
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
			count: counts.collections,
			columns: {
				title: f.valuesFromArray({ values: categories.map((c) => `${c} Study Pack`) }),
				description: f.valuesFromArray({ values: categories.map((c) => `Curated ${c} materials and practice sets`) }),
				quizCount: f.int({ minValue: 0, maxValue: 20 }),
				isPublic: f.boolean(),
			},
		},
		quizzes: {
			count: counts.quizzes,
			columns: {
				collectionId: undefined,
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
			count: counts.questions,
			columns: {
				type: f.valuesFromArray({ values: questionTypes }),
				questionText: f.loremIpsum({ sentencesCount: 1 }),
				data: f.json(),
				orderIndex: f.int({ minValue: 0, maxValue: 49 }),
			},
		},
		quizSnapshots: {
			count: counts.quizSnapshots,
			columns: {
				version: f.int({ minValue: 1, maxValue: 5 }),
				title: f.loremIpsum({ sentencesCount: 1 }),
				description: f.loremIpsum({ sentencesCount: 2 }),
				category: f.valuesFromArray({ values: categories }),
				questionCount: f.int({ minValue: 5, maxValue: 50 }),
			},
		},
		questionsSnapshots: {
			count: counts.questionsSnapshots,
			columns: {
				type: f.valuesFromArray({ values: questionTypes }),
				questionText: f.loremIpsum({ sentencesCount: 1 }),
				data: f.json(),
				orderIndex: f.int({ minValue: 0, maxValue: 49 }),
			},
		},
		gameSessions: {
			count: counts.gameSessions,
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
			count: counts.gameParticipants,
			columns: {
				score: f.int({ minValue: 0, maxValue: 10000 }),
				rank: f.int({ minValue: 1, maxValue: 100 }),
			},
		},
		posts: {
			count: counts.posts,
			columns: {
				text: f.valuesFromArray({ values: categories.map((c) => `Sharing a new ${c} quiz – feedback welcome!`) }),
				postType: f.valuesFromArray({ values: ['text', 'text', 'text', 'image', 'quiz'] }),
				imageUrl: undefined,
				questionType: undefined,
				questionText: undefined,
				questionData: undefined,
				likesCount: f.int({ minValue: 0, maxValue: 500 }),
				commentsCount: f.int({ minValue: 0, maxValue: 0 }),
			},
		},
		postLikes: {
			count: counts.postLikes,
		},
		follows: {
			count: counts.follows,
		},
		notifications: {
			count: 0,
			columns: {
				type: f.valuesFromArray({ values: notificationTypes }),
				isUnread: f.boolean(),
			},
		},
	}));

	const quizzes = await db.select().from(schema.quizzes);
	for (const q of quizzes) {
		const title = generateQuizTitle(q.category ?? 'General');
		const description = generateQuizDescription(q.category ?? 'General');
		await db.update(schema.quizzes).set({ title, description }).where(eq(schema.quizzes.id, q.id));
	}

	const questions = await db
		.select({
			id: schema.questions.id,
			quizId: schema.questions.quizId,
			type: schema.questions.type,
			orderIndex: schema.questions.orderIndex,
		})
		.from(schema.questions);

	const quizMap = new Map<string, { category: string | null }>();
	for (const q of quizzes) quizMap.set(q.id, { category: q.category ?? null });

	for (const qs of questions) {
		const meta = quizMap.get(qs.quizId);
		const questionText = generateQuestionText(meta?.category ?? null, qs.type as any, qs.orderIndex);
		const data = generateQuestionData(qs.type as any);
		await db.update(schema.questions).set({ questionText, data }).where(eq(schema.questions.id, qs.id));
	}

	const quizSnapshots = await db.select().from(schema.quizSnapshots);
	for (const s of quizSnapshots) {
		const title = generateQuizTitle(s.category ?? 'General');
		const description = generateQuizDescription(s.category ?? 'General');
		await db.update(schema.quizSnapshots).set({ title, description }).where(eq(schema.quizSnapshots.id, s.id));
	}

	const questionSnapshots = await db
		.select({
			id: schema.questionsSnapshots.id,
			snapshotId: schema.questionsSnapshots.snapshotId,
			type: schema.questionsSnapshots.type,
			orderIndex: schema.questionsSnapshots.orderIndex,
		})
		.from(schema.questionsSnapshots);

	const snapMap = new Map<string, { category: string | null }>();
	for (const s of quizSnapshots) snapMap.set(s.id, { category: s.category ?? null });

	for (const qs of questionSnapshots) {
		const meta = snapMap.get(qs.snapshotId);
		const questionText = generateQuestionText(meta?.category ?? null, qs.type as any, qs.orderIndex);
		const data = generateQuestionData(qs.type as any);
		await db.update(schema.questionsSnapshots).set({ questionText, data }).where(eq(schema.questionsSnapshots.id, qs.id));
	}

	const posts = await db.select().from(schema.posts);
	const users = await db.select({ id: schema.users.id }).from(schema.users);

	for (const post of posts) {
		const commentCount = Math.floor(Math.random() * (SEED_COMMENTS_COUNT_PER_POST * 2 + 1));

		for (let i = 0; i < commentCount; i++) {
			const randomUser = users[Math.floor(Math.random() * users.length)];
			await db.insert(schema.comments).values({
				postId: post.id,
				userId: randomUser.id,
				content: `Comment ${i + 1} on this post`,
				likesCount: Math.floor(Math.random() * 10),
			});
		}

		if (commentCount > 0) {
			await db.update(schema.posts).set({ commentsCount: commentCount }).where(eq(schema.posts.id, post.id));
		}
	}

	if (seedImageUrls?.posts && seedImageUrls.posts.length > 0) {
		const imagePosts = posts.filter((p: any) => p.postType === 'image');
		console.log(`  🖼️  Assigning URLs to ${imagePosts.length} image posts...`);

		for (let i = 0; i < imagePosts.length; i++) {
			const imageUrl = seedImageUrls.posts[i % seedImageUrls.posts.length];
			await db.update(schema.posts).set({ imageUrl }).where(eq(schema.posts.id, imagePosts[i].id));
		}
	}

	if (seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0) {
		const quizPosts = posts.filter((p: any) => p.postType === 'quiz');
		console.log(`  🧩 Assigning URLs to quiz posts with images...`);

		let assignedCount = 0;
		for (let i = 0; i < quizPosts.length; i++) {
			if (Math.random() < 0.3) {
				const imageUrl = seedImageUrls.quizzes[i % seedImageUrls.quizzes.length];
				await db.update(schema.posts).set({ imageUrl }).where(eq(schema.posts.id, quizPosts[i].id));
				assignedCount++;
			}
		}
		console.log(`  ✅ Assigned images to ${assignedCount} quiz posts`);
	}

	if (seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0) {
		console.log(`  📚 Assigning cover images to quizzes...`);

		let assignedQuizCount = 0;
		for (let i = 0; i < quizzes.length; i++) {
			if (Math.random() < 0.3) {
				const imageUrl = seedImageUrls.quizzes[i % seedImageUrls.quizzes.length];
				await db.update(schema.quizzes).set({ imageUrl }).where(eq(schema.quizzes.id, quizzes[i].id));
				assignedQuizCount++;
			}
		}
		console.log(`  ✅ Assigned cover images to ${assignedQuizCount} quizzes`);
	}

	if (seedImageUrls?.profiles && seedImageUrls.profiles.length > 0) {
		console.log(`  👤 Assigning profile pictures to users...`);

		for (let i = 0; i < users.length; i++) {
			const profilePictureUrl = seedImageUrls.profiles[i % seedImageUrls.profiles.length];
			await db.update(schema.users).set({ profilePictureUrl }).where(eq(schema.users.id, users[i].id));
		}
		console.log(`  ✅ Assigned profile pictures to ${users.length} users`);
	}

	if (counts.savedQuizzes > 0 && users.length > 0 && quizzes.length > 0) {
		console.log(`  ⭐ Creating ${counts.savedQuizzes} unique favorite quizzes...`);

		const usedPairs = new Set<string>();
		const favoriteQuizzesToInsert = [];

		let attempts = 0;
		const maxAttempts = counts.savedQuizzes * 10;

		while (favoriteQuizzesToInsert.length < counts.savedQuizzes && attempts < maxAttempts) {
			const randomUser = users[Math.floor(Math.random() * users.length)];
			const randomQuiz = quizzes[Math.floor(Math.random() * quizzes.length)];
			const pairKey = `${randomUser.id}:${randomQuiz.id}`;

			if (!usedPairs.has(pairKey)) {
				usedPairs.add(pairKey);
				favoriteQuizzesToInsert.push({
					userId: randomUser.id,
					quizId: randomQuiz.id,
				});
			}
			attempts++;
		}

		if (favoriteQuizzesToInsert.length > 0) {
			await db.insert(schema.favoriteQuizzes).values(favoriteQuizzesToInsert).onConflictDoNothing();
			console.log(`  ✅ Created ${favoriteQuizzesToInsert.length} favorite quizzes`);
		}
	}

	console.log('✅ Regular user data generation completed');
};
