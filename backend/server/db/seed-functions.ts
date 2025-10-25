import { seed } from 'drizzle-seed';
import { eq, desc, sql } from 'drizzle-orm';
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
	vietnameseNames,
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

export const seedAdminUser = async (db: any) => {
	const SEED_ADMIN = process.env.SEED_ADMIN;
	
	if (!SEED_ADMIN) {
		console.log('ℹ️  No SEED_ADMIN specified, skipping admin user creation');
		return;
	}

	console.log('\n🔑 Creating admin user from SEED_ADMIN...');

	if (!supabaseAdmin) {
		console.error('❌ Supabase Admin client not configured. Set SUPABASE_SERVICE_ROLE_KEY in .env');
		console.log('⚠️  Cannot create admin user without Supabase access');
		return;
	}

	console.log(`🔍 Looking up Supabase user: ${SEED_ADMIN}`);
	const { data: supabaseUsers, error } = await supabaseAdmin.auth.admin.listUsers();

	if (error) {
		console.error('❌ Failed to fetch Supabase users:', error);
		return;
	}

	const supabaseUser = supabaseUsers.users.find(
		(u) => u.email?.toLowerCase() === SEED_ADMIN.toLowerCase()
	);

	if (!supabaseUser || !supabaseUser.email) {
		console.error(`❌ User ${SEED_ADMIN} not found in Supabase Auth`);
		console.log('💡 Tip: Create this user in Supabase first, then run db:seed');
		return;
	}

	console.log(`✅ Found Supabase user: ${supabaseUser.email} (UID: ${supabaseUser.id})`);

	const fullName = supabaseUser.user_metadata?.full_name || 
	                 supabaseUser.user_metadata?.name || 
	                 'Admin User';
	const username = SEED_ADMIN.split('@')[0].replace(/[^a-zA-Z0-9]/g, '_');

	const adminUser = {
		id: supabaseUser.id,
		email: supabaseUser.email,
		fullName,
		username,
		accountType: 'admin' as const,
		status: 'active' as const,
		isSetupComplete: true,
		bio: 'Platform Administrator',
		profilePictureUrl: supabaseUser.user_metadata?.avatar_url || 
		                   supabaseUser.user_metadata?.picture || null,
	};

	await db
		.insert(schema.users)
		.values(adminUser)
		.onConflictDoUpdate({
			target: schema.users.id,
			set: {
				accountType: 'admin',
				status: 'active',
				updatedAt: new Date(),
			},
		});

	console.log(`✅ Admin user created/updated: ${supabaseUser.email}`);
	console.log(`   - User ID: ${supabaseUser.id}`);
	console.log(`   - Account Type: admin`);
	console.log(`   - Status: active\n`);
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
				fullName: f.valuesFromArray({ values: vietnameseNames }),
				email: f.email({ provider: 'gmail.com' }),
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
				title: f.valuesFromArray({ values: categories.map((c) => `Bộ đề ${c}`) }),
				description: f.valuesFromArray({ values: categories.map((c) => `Tài liệu và bài tập ${c} được tuyển chọn`) }),
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
				text: f.valuesFromArray({ values: categories.map((c) => `Chia sẻ bộ quiz ${c} mới – rất mong nhận phản hồi!`) }),
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

	// Fix emails to all be @gmail.com for regular users (not employees)
	console.log('📧 Updating emails and usernames for regular users...');
	const allUsers = await db.select().from(schema.users);
	const usedUsernames = new Set<string>();
	
	for (const user of allUsers) {
		// Skip employees (@quizzy.dev) and SEED_USERS
		if (user.email.endsWith('@quizzy.dev') || SEED_USERS.includes(user.email)) {
			usedUsernames.add(user.username || '');
			continue;
		}
		
		// Convert email to gmail.com
		const emailUsername = user.email.split('@')[0].toLowerCase().replace(/[^a-z0-9]/g, '');
		const newEmail = `${emailUsername}@gmail.com`;
		
		// Generate username from full name (Vietnamese-friendly)
		// Remove diacritics and convert to lowercase ASCII
		const nameSlug = user.fullName
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '') // Remove diacritics
			.toLowerCase()
			.replace(/đ/g, 'd') // Replace đ with d
			.replace(/[^a-z0-9\s]/g, '') // Remove special chars
			.trim()
			.replace(/\s+/g, ''); // Remove spaces
		
		// Ensure uniqueness by adding numbers if needed
		let newUsername = nameSlug;
		let counter = 1;
		while (usedUsernames.has(newUsername)) {
			newUsername = `${nameSlug}${counter}`;
			counter++;
		}
		usedUsernames.add(newUsername);
		
		await db.update(schema.users).set({ 
			email: newEmail,
			username: newUsername 
		}).where(eq(schema.users.id, user.id));
	}
	console.log('✅ Updated emails and usernames');

	const quizzes = await db.select().from(schema.quizzes);
	for (const q of quizzes) {
		const title = generateQuizTitle(q.category ?? 'Kiến thức chung');
		const description = generateQuizDescription(q.category ?? 'Kiến thức chung');
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
		const title = generateQuizTitle(s.category ?? 'Kiến thức chung');
		const description = generateQuizDescription(s.category ?? 'Kiến thức chung');
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
			const commentTexts = [
				'Hay quá! 👍',
				'Bài quiz rất thú vị',
				'Cảm ơn bạn đã chia sẻ',
				'Mình đã học được nhiều điều',
				'Quiz này khó quá 😅',
				'Rất hữu ích cho việc học',
				'Câu hỏi hay và logic',
				'Chờ bài mới của bạn!',
			];
			await db.insert(schema.comments).values({
				postId: post.id,
				userId: randomUser.id,
				content: commentTexts[i % commentTexts.length],
				likesCount: Math.floor(Math.random() * 10),
			});
		}

		if (commentCount > 0) {
			await db.update(schema.posts).set({ commentsCount: commentCount }).where(eq(schema.posts.id, post.id));
		}
	}

	// Process image posts: assign proper image URLs
	console.log('  🖼️  Processing image posts...');
	const imagePosts = posts.filter((p: any) => p.postType === 'image');
	
	for (let i = 0; i < imagePosts.length; i++) {
		const post = imagePosts[i];
		let imageUrl = null;
		
		// Assign actual image URL if available
		if (seedImageUrls?.posts && seedImageUrls.posts.length > 0) {
			imageUrl = seedImageUrls.posts[i % seedImageUrls.posts.length];
		}
		
		// Clean up any garbage values
		await db.update(schema.posts).set({ 
			imageUrl,
			questionType: null,
			questionText: null,
			questionData: null
		}).where(eq(schema.posts.id, post.id));
	}
	console.log(`  ✅ Processed ${imagePosts.length} image posts`);

	// Process quiz posts: assign proper question data and clean up garbage values
	console.log('  🧩 Processing quiz posts...');
	const quizPosts = posts.filter((p: any) => p.postType === 'quiz');
	
	for (let i = 0; i < quizPosts.length; i++) {
		const post = quizPosts[i];
		
		// Generate proper question data for quiz posts
		const questionType = questionTypes[Math.floor(Math.random() * questionTypes.length)];
		const randomCategory = categories[Math.floor(Math.random() * categories.length)];
		const questionText = generateQuestionText(randomCategory, questionType, i);
		const questionData = generateQuestionData(questionType);
		
		// Assign image URL to 30% of quiz posts
		let imageUrl = null;
		if (seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0 && Math.random() < 0.3) {
			imageUrl = seedImageUrls.quizzes[i % seedImageUrls.quizzes.length];
		}
		
		await db.update(schema.posts).set({ 
			imageUrl,
			questionType: questionType as any,
			questionText,
			questionData
		}).where(eq(schema.posts.id, post.id));
	}
	console.log(`  ✅ Processed ${quizPosts.length} quiz posts with proper question data`);

	// Clean up text posts: ensure no garbage values
	console.log('  📝 Cleaning up text posts...');
	const textPosts = posts.filter((p: any) => p.postType === 'text');
	
	for (const post of textPosts) {
		await db.update(schema.posts).set({ 
			imageUrl: null,
			questionType: null,
			questionText: null,
			questionData: null
		}).where(eq(schema.posts.id, post.id));
	}
	console.log(`  ✅ Cleaned ${textPosts.length} text posts`);

	// Clean up and assign quiz cover images
	console.log('  📚 Processing quiz cover images...');
	
	for (let i = 0; i < quizzes.length; i++) {
		let imageUrl = null;
		
		// Assign image to 30% of quizzes
		if (seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0 && Math.random() < 0.3) {
			imageUrl = seedImageUrls.quizzes[i % seedImageUrls.quizzes.length];
		}
		
		await db.update(schema.quizzes).set({ imageUrl }).where(eq(schema.quizzes.id, quizzes[i].id));
	}
	
	const [quizzesWithImagesCount] = await db
		.select({ count: sql<number>`cast(count(*) as int)` })
		.from(schema.quizzes)
		.where(sql`image_url IS NOT NULL`);
	console.log(`  ✅ Assigned cover images to ${quizzesWithImagesCount?.count || 0} quizzes`);

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
