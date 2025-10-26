import { seed } from 'drizzle-seed';
import { eq, desc, sql, inArray } from 'drizzle-orm';
import * as schema from './schema';
import { getS3File, BUCKETS, type BucketName } from '../lib/s3';
import { supabaseAdmin } from '../lib/supabase';
import * as path from 'path';
import * as fs from 'fs/promises';

// ============================================================================
// SEED DATA CONFIGURATION AND CONSTANTS
// ============================================================================

const getRequiredEnv = (key: string): string => {
	const value = process.env[key];
	if (!value) {
		throw new Error(`Missing required environment variable: ${key}`);
	}
	return value;
};

const getRequiredNumberEnv = (key: string): number => {
	const value = getRequiredEnv(key);
	const num = Number(value);
	if (isNaN(num)) {
		throw new Error(`Environment variable ${key} must be a number, got: ${value}`);
	}
	return num;
};

export const SEED_ADMIN = process.env.SEED_ADMIN || '';
export const SEED_USERS = process.env.SEED_USERS?.split(',').map((email) => email.trim()) || [];
export const SEED_USERS_COUNT = getRequiredNumberEnv('SEED_USERS_COUNT');
export const SEED_COLLECTIONS_COUNT_PER_USER = getRequiredNumberEnv('SEED_COLLECTIONS_COUNT_PER_USER');
export const SEED_QUIZZES_COUNT_PER_USER = getRequiredNumberEnv('SEED_QUIZZES_COUNT_PER_USER');
export const SEED_QUESTIONS_PER_QUIZ_COUNT = getRequiredNumberEnv('SEED_QUESTIONS_PER_QUIZ_COUNT');
export const SEED_QUIZ_SNAPSHOTS_COUNT_PER_QUIZ = getRequiredNumberEnv('SEED_QUIZ_SNAPSHOTS_COUNT_PER_QUIZ');
export const SEED_GAME_SESSIONS_COUNT_PER_QUIZ = getRequiredNumberEnv('SEED_GAME_SESSIONS_COUNT_PER_QUIZ');
export const SEED_GAME_PARTICIPANTS_PER_SESSION_COUNT = getRequiredNumberEnv('SEED_GAME_PARTICIPANTS_PER_SESSION_COUNT');
export const SEED_POSTS_COUNT_PER_USER = getRequiredNumberEnv('SEED_POSTS_COUNT_PER_USER');
export const SEED_COMMENTS_COUNT_PER_POST = getRequiredNumberEnv('SEED_COMMENTS_COUNT_PER_POST');
export const SEED_POST_LIKES_COUNT_PER_POST = getRequiredNumberEnv('SEED_POST_LIKES_COUNT_PER_POST');
export const SEED_COMMENT_LIKES_COUNT_PER_COMMENT = getRequiredNumberEnv('SEED_COMMENT_LIKES_COUNT_PER_COMMENT');
export const SEED_FAVORITE_QUIZZES_COUNT_PER_USER = getRequiredNumberEnv('SEED_FAVORITE_QUIZZES_COUNT_PER_USER');
export const SEED_FOLLOWS_COUNT_PER_USER = getRequiredNumberEnv('SEED_FOLLOWS_COUNT_PER_USER');
export const SEED_NOTIFICATIONS_COUNT_PER_POST = getRequiredNumberEnv('SEED_NOTIFICATIONS_COUNT_PER_POST');

export const INITIAL_CATEGORIES = [
	{
		name: 'General Knowledge',
		slug: 'general-knowledge',
		description: 'Broad topics across various subjects',
		imageUrl: 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=400&h=300&fit=crop',
	},
	{
		name: 'Science',
		slug: 'science',
		description: 'Physics, Chemistry, Biology, and more',
		imageUrl: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400&h=300&fit=crop',
	},
	{
		name: 'Math',
		slug: 'math',
		description: 'Mathematics and problem solving',
		imageUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400&h=300&fit=crop',
	},
	{
		name: 'History',
		slug: 'history',
		description: 'World history and historical events',
		imageUrl: 'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=400&h=300&fit=crop',
	},
	{
		name: 'Geography',
		slug: 'geography',
		description: 'Places, maps, and world geography',
		imageUrl: 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=400&h=300&fit=crop',
	},
	{
		name: 'Literature',
		slug: 'literature',
		description: 'Books, authors, and literary works',
		imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=300&fit=crop',
	},
	{
		name: 'Music',
		slug: 'music',
		description: 'Music theory, artists, and genres',
		imageUrl: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=300&fit=crop',
	},
	{
		name: 'Movies',
		slug: 'movies',
		description: 'Film, cinema, and entertainment',
		imageUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400&h=300&fit=crop',
	},
	{
		name: 'Sports',
		slug: 'sports',
		description: 'Athletics, games, and competitions',
		imageUrl: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&h=300&fit=crop',
	},
	{
		name: 'Technology',
		slug: 'technology',
		description: 'Computers, programming, and tech',
		imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400&h=300&fit=crop',
	},
	{
		name: 'Programming',
		slug: 'programming',
		description: 'Coding, algorithms, and software',
		imageUrl: 'https://images.unsplash.com/photo-1542831371-29b0f74f9713?w=400&h=300&fit=crop',
	},
	{
		name: 'Art',
		slug: 'art',
		description: 'Visual arts, design, and creativity',
		imageUrl: 'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=400&h=300&fit=crop',
	},
	{
		name: 'Other',
		slug: 'other',
		description: 'Miscellaneous topics',
		imageUrl: 'https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=400&h=300&fit=crop',
	},
];

export const questionTypes: string[] = [
	'single_choice',
	'checkbox',
	'true_false',
	'type_answer',
	'reorder',
	'drop_pin',
];

export const accountTypes = ['user', 'employee'];

export const bios = [
	'Đam mê quiz và giáo dục 📚',
	'Học cái gì cũng thích 🎓',
	'Tạo nội dung giáo dục hấp dẫn',
	'Yêu thích chia sẻ kiến thức',
	'Làm cho học tập trở nên vui vẻ',
	'Giáo viên ban ngày, tác giả quiz ban đêm',
	'Xây dựng trải nghiệm học tập tốt hơn',
	'Người ủng hộ công nghệ giáo dục',
];

export const vietnameseNames = [
	'Nguyễn Văn An', 'Trần Thị Bình', 'Lê Hoàng Cường', 'Phạm Thị Dung', 
	'Hoàng Văn Em', 'Đặng Thị Phương', 'Võ Minh Giang', 'Bùi Thị Hương',
	'Đỗ Văn Hùng', 'Ngô Thị Lan', 'Dương Văn Khoa', 'Lý Thị Linh',
	'Mai Văn Minh', 'Phan Thị Nga', 'Trương Văn Ơn', 'Hồ Thị Phượng',
	'Tô Văn Quang', 'Đinh Thị Như', 'Vũ Văn Sơn', 'Cao Thị Tâm',
];

export const notificationTypes = ['like', 'comment', 'follow', 'quiz_share', 'game_invite'];

export const generateQuestionData = (type: string) => {
	const baseData = {
		timeLimit: 15 + Math.floor(Math.random() * 46),
		points: [50, 100, 150][Math.floor(Math.random() * 3)],
		explanation: 'Câu hỏi này kiểm tra sự hiểu biết của bạn về chủ đề.',
	};
	
	switch (type) {
		case 'single_choice':
			return {
				...baseData,
				options: [
					{ text: 'Phương án A', isCorrect: false },
					{ text: 'Phương án B', isCorrect: true },
					{ text: 'Phương án C', isCorrect: false },
					{ text: 'Phương án D', isCorrect: false },
				],
			};
		case 'checkbox':
			return {
				...baseData,
				options: [
					{ text: 'Phương án A', isCorrect: true },
					{ text: 'Phương án B', isCorrect: true },
					{ text: 'Phương án C', isCorrect: false },
					{ text: 'Phương án D', isCorrect: false },
				],
			};
		case 'true_false':
			return {
				...baseData,
				correctAnswer: Math.random() > 0.5,
			};
		case 'type_answer':
			return {
				...baseData,
				correctAnswer: 'gõ câu trả lời',
				caseSensitive: false,
			};
		case 'reorder':
			return {
				...baseData,
				items: [
					{ id: 1, text: 'Mục thứ nhất', correctOrder: 0 },
					{ id: 2, text: 'Mục thứ hai', correctOrder: 1 },
					{ id: 3, text: 'Mục thứ ba', correctOrder: 2 },
				],
			};
		case 'drop_pin':
			return {
				...baseData,
				correctLocation: { lat: 21.0285, lng: 105.8542 }, // Hanoi coordinates
				tolerance: 0.1,
			};
		default:
			return baseData;
	}
};

export const generateQuizTitle = (category: string) => {
	const templates = [
		`Bộ đề ${category} cơ bản`,
		`Làm chủ ${category}`,
		`Nền tảng ${category}`,
		`Thử thách ${category}`,
		`Nhập môn ${category}`,
	];
	return templates[Math.floor(Math.random() * templates.length)];
};

export const generateQuizDescription = (category: string) => {
	const templates = [
		`Kiểm tra kiến thức cốt lõi của bạn về ${category} với các câu hỏi cân bằng độ khó.`,
		`Bộ câu hỏi ${category} được tuyển chọn giúp bạn luyện tập hiệu quả.`,
		`Khám phá các khái niệm chính trong ${category} với các câu hỏi rõ ràng, tập trung.`,
		`Trau dồi kỹ năng ${category} của bạn với bài quiz hấp dẫn này.`,
	];
	return templates[Math.floor(Math.random() * templates.length)];
};

export const generateQuestionText = (category: string | null, type: string, index: number) => {
	const base = category ?? 'Kiến thức chung';
	switch (type) {
		case 'single_choice':
			return `(${index + 1}) Câu nào đúng về ${base}?`;
		case 'checkbox':
			return `(${index + 1}) Chọn tất cả câu trả lời đúng về ${base}.`;
		case 'true_false':
			return `(${index + 1}) Đúng hay Sai: Một sự thật phổ biến về ${base}.`;
		case 'type_answer':
			return `(${index + 1}) Gõ thuật ngữ chính xác về ${base}.`;
		case 'reorder':
			return `(${index + 1}) Sắp xếp các bước ${base} theo đúng thứ tự.`;
		case 'drop_pin':
			return `(${index + 1}) Xác định vị trí liên quan đến ${base}.`;
		default:
			return `(${index + 1}) Câu hỏi về ${base}.`;
	}
};

export interface SeedImageUrls {
	posts: string[];
	quizzes: string[];
	profiles: string[];
}

export const FIXED_USERS: Array<typeof schema.users.$inferInsert> = [
  {
    email: 'nguyen.van.an@quizzy.dev',
    fullName: 'Nguyễn Văn An',
    username: 'nguyenvanan',
    bio: 'Tuyển chọn các bộ quiz chất lượng cao',
    accountType: 'employee',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000001?v=4',
  },
  {
    email: 'tran.thi.binh@quizzy.dev',
    fullName: 'Trần Thị Bình',
    username: 'tranthibinh',
    bio: 'Học mỗi ngày một chút 📚',
    accountType: 'employee',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000002?v=4',
  },
  {
    email: 'le.hoang.cuong@quizzy.dev',
    fullName: 'Lê Hoàng Cường',
    username: 'lehoangcuong',
    bio: 'Làm cho học tập trở nên vui vẻ hơn',
    accountType: 'employee',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000003?v=4',
  },
  {
    email: 'pham.thi.dung@quizzy.dev',
    fullName: 'Phạm Thị Dung',
    username: 'phamthidung',
    bio: 'Đam mê quiz và giáo dục',
    accountType: 'employee',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000004?v=4',
  },
  {
    email: 'hoang.van.em@quizzy.dev',
    fullName: 'Hoàng Văn Em',
    username: 'hoangvanem',
    bio: 'Tạo nội dung giáo dục hấp dẫn',
    accountType: 'employee',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000005?v=4',
  },
  {
    email: 'dang.thi.phuong@quizzy.dev',
    fullName: 'Đặng Thị Phương',
    username: 'dangthiphuong',
    bio: 'Xây dựng trải nghiệm học tập tốt hơn',
    accountType: 'employee',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000006?v=4',
  },
];

export const FIXED_USER_COLLECTIONS = [
  { email: 'nguyen.van.an@quizzy.dev', collections: [
    { title: 'Bộ đề Khoa học', description: 'Tài nguyên khoa học toàn diện cho học sinh' },
    { title: 'Bộ sưu tập Lịch sử', description: 'Các sự kiện và dòng thời gian lịch sử thế giới' },
    { title: 'Toán học cơ bản', description: 'Các khái niệm toán học cốt lõi và bài tập' }
  ]},
  { email: 'tran.thi.binh@quizzy.dev', collections: [
    { title: 'Yêu thích của tôi', description: 'Các quiz tôi thích luyện tập' },
    { title: 'Nhóm học tập', description: 'Chia sẻ quiz với bạn cùng lớp' }
  ]},
  { email: 'le.hoang.cuong@quizzy.dev', collections: [
    { title: 'Bộ sưu tập Văn học', description: 'Nghiên cứu văn học cổ điển và hiện đại' },
    { title: 'Nghệ thuật & Âm nhạc', description: 'Khám phá nghệ thuật sáng tạo' }
  ]},
  { email: 'pham.thi.dung@quizzy.dev', collections: [
    { title: 'Kinh doanh cơ bản', description: 'Các khái niệm và chiến lược kinh doanh cốt lõi' },
    { title: 'Xu hướng Công nghệ', description: 'Mới nhất về công nghệ và đổi mới' }
  ]},
  { email: 'hoang.van.em@quizzy.dev', collections: [
    { title: 'Quiz luyện tập', description: 'Tài liệu luyện tập và ôn tập hàng ngày' }
  ]},
  { email: 'dang.thi.phuong@quizzy.dev', collections: [
    { title: 'Phát triển chuyên nghiệp', description: 'Phát triển sự nghiệp và xây dựng kỹ năng' },
    { title: 'Đào tạo Kỹ năng', description: 'Tài nguyên đào tạo kỹ thuật thực hành' }
  ]}
];

export const getRegularUserCounts = (totalUsers: number) => {
	const SEED_COLLECTIONS_COUNT = totalUsers * SEED_COLLECTIONS_COUNT_PER_USER;
	const SEED_QUIZZES_COUNT = totalUsers * SEED_QUIZZES_COUNT_PER_USER;
	const SEED_QUESTIONS_COUNT = SEED_QUIZZES_COUNT * SEED_QUESTIONS_PER_QUIZ_COUNT;
	const SEED_QUIZ_SNAPSHOTS_COUNT = SEED_QUIZZES_COUNT * SEED_QUIZ_SNAPSHOTS_COUNT_PER_QUIZ;
	const SEED_QUESTIONS_SNAPSHOTS_COUNT = SEED_QUIZ_SNAPSHOTS_COUNT * SEED_QUESTIONS_PER_QUIZ_COUNT;
	const SEED_GAME_SESSIONS_COUNT = SEED_QUIZZES_COUNT * SEED_GAME_SESSIONS_COUNT_PER_QUIZ;
	const SEED_GAME_PARTICIPANTS_COUNT = SEED_GAME_SESSIONS_COUNT * SEED_GAME_PARTICIPANTS_PER_SESSION_COUNT;
	const SEED_POSTS_COUNT = totalUsers * SEED_POSTS_COUNT_PER_USER;
	const SEED_POST_LIKES_COUNT = SEED_POSTS_COUNT * SEED_POST_LIKES_COUNT_PER_POST;
	const SEED_FAVORITE_QUIZZES_COUNT = totalUsers * SEED_FAVORITE_QUIZZES_COUNT_PER_USER;
	const SEED_FOLLOWS_COUNT = totalUsers * SEED_FOLLOWS_COUNT_PER_USER;
	
	return {
		users: totalUsers,
		collections: SEED_COLLECTIONS_COUNT,
		quizzes: SEED_QUIZZES_COUNT,
		questions: SEED_QUESTIONS_COUNT,
		quizSnapshots: SEED_QUIZ_SNAPSHOTS_COUNT,
		questionsSnapshots: SEED_QUESTIONS_SNAPSHOTS_COUNT,
		gameSessions: SEED_GAME_SESSIONS_COUNT,
		gameParticipants: SEED_GAME_PARTICIPANTS_COUNT,
		savedQuizzes: SEED_FAVORITE_QUIZZES_COUNT,
		posts: SEED_POSTS_COUNT,
		postLikes: SEED_POST_LIKES_COUNT,
		follows: SEED_FOLLOWS_COUNT,
		notifications: 0,
	};
};

// ============================================================================
// SEED FUNCTIONS
// ============================================================================

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

	try {
		await fs.access(postsDir);
		const postFiles = await fs.readdir(postsDir);
		const postJpgs = postFiles.filter((f) => f.endsWith('.jpg') || f.endsWith('.jpeg'));

		const postUploadPromises = postJpgs.map(file => uploadSeedImage(db, path.join(postsDir, file), seedUserId, BUCKETS.POSTS));
		const postResults = await Promise.all(postUploadPromises);
		postUrls.push(...postResults.filter((url): url is string => url !== null));
	} catch (error) {
		// Posts directory not found - skip
	}

	try {
		await fs.access(quizzesDir);
		const quizFiles = await fs.readdir(quizzesDir);
		const quizJpgs = quizFiles.filter((f) => f.endsWith('.jpg') || f.endsWith('.jpeg'));

		const quizUploadPromises = quizJpgs.map(file => uploadSeedImage(db, path.join(quizzesDir, file), seedUserId, BUCKETS.QUIZZES));
		const quizResults = await Promise.all(quizUploadPromises);
		quizUrls.push(...quizResults.filter((url): url is string => url !== null));
	} catch (error) {
		// Quizzes directory not found - skip
	}

	try {
		await fs.access(profilesDir);
		const profileFiles = await fs.readdir(profilesDir);
		const profileJpgs = profileFiles.filter((f) => f.endsWith('.jpg') || f.endsWith('.jpeg'));

		const profileUploadPromises = profileJpgs.map(file => uploadSeedImage(db, path.join(profilesDir, file), seedUserId, BUCKETS.PROFILES));
		const profileResults = await Promise.all(profileUploadPromises);
		profileUrls.push(...profileResults.filter((url): url is string => url !== null));
	} catch (error) {
		// Profiles directory not found - skip
	}

	console.log(`✅ Images: ${postUrls.length} posts, ${quizUrls.length} quizzes, ${profileUrls.length} profiles`);

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
	
	if (!SEED_ADMIN) return;

	try {
		if (!supabaseAdmin) {
			console.error('❌ Supabase Admin not configured - cannot create admin user');
			return;
		}

		const { data: supabaseUsers, error } = await supabaseAdmin.auth.admin.listUsers();
		if (error) {
			console.error('❌ Failed to fetch Supabase users:', error.message);
			return;
		}

		const supabaseUser = supabaseUsers.users.find(
			(u) => u.email?.toLowerCase() === SEED_ADMIN.toLowerCase()
		);

		if (!supabaseUser || !supabaseUser.email) {
			console.error(`❌ Admin user ${SEED_ADMIN} not found in Supabase`);
			return;
		}

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

		console.log(`✅ Admin: ${supabaseUser.email}`);
	} catch (error) {
		console.error('❌ Failed to seed admin user:', error);
	}
};

export const seedFixedUsersData = async (db: any, categoryMap?: Map<string, string>, seedImageUrls?: SeedImageUrls) => {
	try {
		let collectionIndex = 0;
		for (const fixedUserConfig of FIXED_USER_COLLECTIONS) {
			const [user] = await db.select().from(schema.users).where(eq(schema.users.email, fixedUserConfig.email));
			if (!user) continue;

			for (const collectionData of fixedUserConfig.collections) {
				const imageUrl = seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0 
					? seedImageUrls.quizzes[collectionIndex % seedImageUrls.quizzes.length]
					: null;

				const [newCollection] = await db
					.insert(schema.collections)
					.values({
						userId: user.id,
						title: collectionData.title,
						description: collectionData.description,
						imageUrl,
						quizCount: 0,
						isPublic: true,
					})
					.returning();

				collectionIndex++;

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
	} catch (error) {
		console.error('❌ Failed to seed fixed users data:', error);
		throw error;
	}
};

export const seedSpecificUsers = async (db: any) => {
	if (SEED_USERS.length === 0) return;

	try {
		if (!supabaseAdmin) {
			console.error('❌ Supabase Admin not configured - skipping SEED_USERS');
			return;
		}

		const { data: supabaseUsers, error } = await supabaseAdmin.auth.admin.listUsers();
		if (error) {
			console.error('❌ Failed to fetch Supabase users:', error.message);
			return;
		}

		const emailToUid = new Map<string, string>();
		for (const supabaseUser of supabaseUsers.users) {
			if (supabaseUser.email) {
				emailToUid.set(supabaseUser.email.toLowerCase(), supabaseUser.id);
			}
		}

		let createdCount = 0;
		for (const email of SEED_USERS) {
			const supabaseUid = emailToUid.get(email.toLowerCase());
			if (!supabaseUid) continue;

			const randomYear = 1990 + Math.floor(Math.random() * 15);
			const randomMonth = Math.floor(Math.random() * 12);
			const randomDay = Math.floor(Math.random() * 28) + 1;
			const dob = `${randomYear}-${String(randomMonth + 1).padStart(2, '0')}-${String(randomDay).padStart(2, '0')}`;

			const user = {
				id: supabaseUid,
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
			createdCount++;
		}

		if (createdCount > 0) {
			console.log(`✅ Seed users: ${createdCount} created`);
		}
	} catch (error) {
		console.error('❌ Failed to seed specific users:', error);
	}
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

export const seedRegularUsers = async (db: any, seedImageUrls?: SeedImageUrls, categoryMap?: Map<string, string>) => {
	// Calculate total users including SEED_USERS
	const totalUserCount = SEED_USERS_COUNT + SEED_USERS.length;
	const counts = getRegularUserCounts(totalUserCount);
	
	// Get all category IDs for random assignment
	const categoryIds = categoryMap ? Array.from(categoryMap.values()) : [];

	await seed(db, seedSchemaDef, { count: 10 }).refine((f) => ({
		users: {
			count: SEED_USERS_COUNT,
			columns: {
				fullName: f.valuesFromArray({ values: vietnameseNames }),
				email: f.valuesFromArray({ 
					values: Array.from({ length: SEED_USERS_COUNT }, (_, i) => 
						`user${String(i + 1).padStart(4, '0')}@gmail.com`
					),
					isUnique: true 
				}),
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
				title: f.loremIpsum({ sentencesCount: 2 }),
				description: f.loremIpsum({ sentencesCount: 3 }),
				quizCount: f.int({ minValue: 0, maxValue: 20 }),
				isPublic: f.boolean(),
			},
		},
		quizzes: {
			count: counts.quizzes,
			columns: {
				collectionId: undefined,
				categoryId: categoryIds.length > 0 ? f.valuesFromArray({ values: categoryIds }) : undefined,
				title: f.loremIpsum({ sentencesCount: 1 }),
				description: f.loremIpsum({ sentencesCount: 2 }),
				category: undefined,
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
				category: undefined,
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
				text: f.loremIpsum({ sentencesCount: 2 }),
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
	const allUsers = await db.select().from(schema.users);
	const usedUsernames = new Set<string>();
	const userUpdates = [];
	
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
		
		userUpdates.push({
			id: user.id,
			email: newEmail,
			username: newUsername
		});
	}

	// Simple individual updates to avoid parameter limit
	console.log(`📝 Updating ${userUpdates.length} users...`);
	for (let i = 0; i < userUpdates.length; i++) {
		const u = userUpdates[i];
		await db.update(schema.users)
			.set({ email: u.email, username: u.username })
			.where(eq(schema.users.id, u.id));
		
		if ((i + 1) % 100 === 0 || i === userUpdates.length - 1) {
			process.stdout.write(`\r   Progress: ${i + 1}/${userUpdates.length} users updated`);
		}
	}
	console.log();

	// Create reverse map: categoryId -> categoryName
	const categoryIdToName = new Map<string, string>();
	if (categoryMap) {
		for (const [name, id] of categoryMap.entries()) {
			categoryIdToName.set(id, name);
		}
	}

	// Map English category names to Vietnamese for title generation
	const categoryNameMap: Record<string, string> = {
		'General Knowledge': 'Kiến thức chung',
		'Science': 'Khoa học',
		'Math': 'Toán học',
		'History': 'Lịch sử',
		'Geography': 'Địa lý',
		'Literature': 'Văn học',
		'Music': 'Âm nhạc',
		'Movies': 'Phim ảnh',
		'Sports': 'Thể thao',
		'Technology': 'Công nghệ',
		'Programming': 'Lập trình',
		'Art': 'Nghệ thuật',
		'Other': 'Khác',
	};

	// Fetch quizzes with their category IDs and prepare bulk updates
	const quizzes = await db.select().from(schema.quizzes);
	
	const quizUpdates = quizzes.map(q => {
		const englishCategoryName = q.categoryId ? categoryIdToName.get(q.categoryId) ?? 'General Knowledge' : 'General Knowledge';
		const vietnameseCategoryName = categoryNameMap[englishCategoryName] || 'Kiến thức chung';
		return {
			id: q.id,
			title: generateQuizTitle(vietnameseCategoryName),
			description: generateQuizDescription(vietnameseCategoryName)
		};
	});

	// Simple individual updates to avoid parameter limit
	console.log(`📝 Updating ${quizUpdates.length} quizzes...`);
	for (let i = 0; i < quizUpdates.length; i++) {
		const u = quizUpdates[i];
		await db.update(schema.quizzes)
			.set({ title: u.title, description: u.description })
			.where(eq(schema.quizzes.id, u.id));
		
		if ((i + 1) % 100 === 0 || i === quizUpdates.length - 1) {
			process.stdout.write(`\r   Progress: ${i + 1}/${quizUpdates.length} quizzes updated`);
		}
	}
	console.log();

	const questions = await db
		.select({
			id: schema.questions.id,
			quizId: schema.questions.quizId,
			type: schema.questions.type,
			orderIndex: schema.questions.orderIndex,
		})
		.from(schema.questions);

	// Build quiz map with Vietnamese category names
	const quizMap = new Map<string, { category: string | null }>();
	for (const q of quizzes) {
		if (q.categoryId) {
			const englishName = categoryIdToName.get(q.categoryId) ?? null;
			const vietnameseName = englishName ? categoryNameMap[englishName] ?? null : null;
			quizMap.set(q.id, { category: vietnameseName });
		} else {
			quizMap.set(q.id, { category: null });
		}
	}

	const questionUpdates = questions.map(qs => {
		const meta = quizMap.get(qs.quizId);
		return {
			id: qs.id,
			questionText: generateQuestionText(meta?.category ?? null, qs.type as any, qs.orderIndex),
			data: generateQuestionData(qs.type as any)
		};
	});

	// Simple individual updates to avoid parameter limit
	console.log(`📝 Updating ${questionUpdates.length} questions...`);
	for (let i = 0; i < questionUpdates.length; i++) {
		const u = questionUpdates[i];
		await db.update(schema.questions)
			.set({ questionText: u.questionText, data: u.data })
			.where(eq(schema.questions.id, u.id));
		
		if ((i + 1) % 500 === 0 || i === questionUpdates.length - 1) {
			process.stdout.write(`\r   Progress: ${i + 1}/${questionUpdates.length} questions updated`);
		}
	}
	console.log();

	const quizSnapshots = await db.select().from(schema.quizSnapshots);
	
	const snapshotUpdates = quizSnapshots.map(s => ({
		id: s.id,
		title: generateQuizTitle('Kiến thức chung'),
		description: generateQuizDescription('Kiến thức chung')
	}));

	// Simple individual updates to avoid parameter limit
	console.log(`📝 Updating ${snapshotUpdates.length} quiz snapshots...`);
	for (let i = 0; i < snapshotUpdates.length; i++) {
		const u = snapshotUpdates[i];
		await db.update(schema.quizSnapshots)
			.set({ title: u.title, description: u.description })
			.where(eq(schema.quizSnapshots.id, u.id));
		
		if ((i + 1) % 100 === 0 || i === snapshotUpdates.length - 1) {
			process.stdout.write(`\r   Progress: ${i + 1}/${snapshotUpdates.length} snapshots updated`);
		}
	}
	console.log();

	const questionSnapshots = await db
		.select({
			id: schema.questionsSnapshots.id,
			snapshotId: schema.questionsSnapshots.snapshotId,
			type: schema.questionsSnapshots.type,
			orderIndex: schema.questionsSnapshots.orderIndex,
		})
		.from(schema.questionsSnapshots);

	const snapMap = new Map<string, { category: string | null }>();
	for (const s of quizSnapshots) snapMap.set(s.id, { category: null });

	const questionSnapshotUpdates = questionSnapshots.map(qs => {
		const meta = snapMap.get(qs.snapshotId);
		return {
			id: qs.id,
			questionText: generateQuestionText(meta?.category ?? null, qs.type as any, qs.orderIndex),
			data: generateQuestionData(qs.type as any)
		};
	});

	// Simple individual updates to avoid parameter limit
	console.log(`📝 Updating ${questionSnapshotUpdates.length} question snapshots...`);
	for (let i = 0; i < questionSnapshotUpdates.length; i++) {
		const u = questionSnapshotUpdates[i];
		await db.update(schema.questionsSnapshots)
			.set({ questionText: u.questionText, data: u.data })
			.where(eq(schema.questionsSnapshots.id, u.id));
		
		if ((i + 1) % 500 === 0 || i === questionSnapshotUpdates.length - 1) {
			process.stdout.write(`\r   Progress: ${i + 1}/${questionSnapshotUpdates.length} question snapshots updated`);
		}
	}
	console.log();

	const posts = await db.select().from(schema.posts);
	const users = await db.select({ id: schema.users.id }).from(schema.users);

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

	const allCommentsToInsert = [];
	const postCommentCounts = new Map<string, number>();

	for (const post of posts) {
		const commentCount = Math.floor(Math.random() * (SEED_COMMENTS_COUNT_PER_POST * 2 + 1));
		postCommentCounts.set(post.id, commentCount);

		for (let i = 0; i < commentCount; i++) {
			const randomUser = users[Math.floor(Math.random() * users.length)];
			allCommentsToInsert.push({
				postId: post.id,
				userId: randomUser.id,
				content: commentTexts[i % commentTexts.length],
				likesCount: Math.floor(Math.random() * 10),
			});
		}
	}

	// Bulk insert comments in chunks (PostgreSQL param limit is 65535, ~5 fields per comment = ~13,000 comments per chunk)
	if (allCommentsToInsert.length > 0) {
		const COMMENT_CHUNK_SIZE = 5000;
		console.log(`📝 Inserting ${allCommentsToInsert.length} comments...`);
		for (let i = 0; i < allCommentsToInsert.length; i += COMMENT_CHUNK_SIZE) {
			const chunk = allCommentsToInsert.slice(i, i + COMMENT_CHUNK_SIZE);
			await db.insert(schema.comments).values(chunk);
			
			const progress = Math.min(i + COMMENT_CHUNK_SIZE, allCommentsToInsert.length);
			process.stdout.write(`\r   Progress: ${progress}/${allCommentsToInsert.length} comments inserted`);
		}
		console.log();
	}

	// Skip updating comment counts for now to avoid parameter limit issues
	// Comment counts will be calculated by the application at runtime

	// Process ALL posts in single bulk operation
	const allPostUpdates = posts.map((post: any, i: number) => {
		if (post.postType === 'image') {
			const imageUrl = seedImageUrls?.posts && seedImageUrls.posts.length > 0
				? seedImageUrls.posts[i % seedImageUrls.posts.length]
				: null;
			return {
				id: post.id,
				imageUrl,
				questionType: null,
				questionText: null,
				questionData: null
			};
		} else if (post.postType === 'quiz') {
			const questionType = questionTypes[Math.floor(Math.random() * questionTypes.length)];
			const questionText = generateQuestionText(null, questionType, i);
			const questionData = generateQuestionData(questionType);
			const imageUrl = seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0 && Math.random() < 0.3
				? seedImageUrls.quizzes[i % seedImageUrls.quizzes.length]
				: null;
			return {
				id: post.id,
				imageUrl,
				questionType: questionType as any,
				questionText,
				questionData
			};
		} else {
			// text posts
			return {
				id: post.id,
				imageUrl: null,
				questionType: null,
				questionText: null,
				questionData: null
			};
		}
	});

	// Simple individual updates to avoid parameter limit
	if (allPostUpdates.length > 0) {
		console.log(`📝 Updating ${allPostUpdates.length} posts...`);
		for (let i = 0; i < allPostUpdates.length; i++) {
			const u = allPostUpdates[i];
			await db.update(schema.posts)
				.set({ 
					imageUrl: u.imageUrl, 
					questionType: u.questionType, 
					questionText: u.questionText, 
					questionData: u.questionData 
				})
				.where(eq(schema.posts.id, u.id));
			
			if ((i + 1) % 100 === 0 || i === allPostUpdates.length - 1) {
				process.stdout.write(`\r   Progress: ${i + 1}/${allPostUpdates.length} posts updated`);
			}
		}
		console.log();
	}

	// Simple individual updates to avoid parameter limit
	if (seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0 && quizzes.length > 0) {
		console.log(`📝 Assigning ${quizzes.length} quiz cover images...`);
		for (let i = 0; i < quizzes.length; i++) {
			const quiz = quizzes[i];
			const imageUrl = seedImageUrls.quizzes[i % seedImageUrls.quizzes.length];
			await db.update(schema.quizzes)
				.set({ imageUrl })
				.where(eq(schema.quizzes.id, quiz.id));
			
			if ((i + 1) % 100 === 0 || i === quizzes.length - 1) {
				process.stdout.write(`\r   Progress: ${i + 1}/${quizzes.length} images assigned`);
			}
		}
		console.log();
	}
	
	const [quizzesWithImagesCount] = await db
		.select({ count: sql<number>`cast(count(*) as int)` })
		.from(schema.quizzes)
		.where(sql`image_url IS NOT NULL`);

	// Simple individual updates to avoid parameter limit
	if (seedImageUrls?.profiles && seedImageUrls.profiles.length > 0) {
		console.log(`📝 Assigning ${users.length} profile pictures...`);
		for (let i = 0; i < users.length; i++) {
			const user = users[i];
			const profilePictureUrl = seedImageUrls.profiles[i % seedImageUrls.profiles.length];
			await db.update(schema.users)
				.set({ profilePictureUrl })
				.where(eq(schema.users.id, user.id));
			
			if ((i + 1) % 100 === 0 || i === users.length - 1) {
				process.stdout.write(`\r   Progress: ${i + 1}/${users.length} profile pictures assigned`);
			}
		}
		console.log();
	}

	// Simple individual updates to avoid parameter limit
	const collections = await db.select().from(schema.collections);
	
	if (seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0 && collections.length > 0) {
		console.log(`📝 Assigning ${collections.length} collection cover images...`);
		for (let i = 0; i < collections.length; i++) {
			const collection = collections[i];
			const imageUrl = seedImageUrls.quizzes[i % seedImageUrls.quizzes.length];
			await db.update(schema.collections)
				.set({ imageUrl })
				.where(eq(schema.collections.id, collection.id));
			
			if ((i + 1) % 100 === 0 || i === collections.length - 1) {
				process.stdout.write(`\r   Progress: ${i + 1}/${collections.length} collection images assigned`);
			}
		}
		console.log();
	}

	if (counts.savedQuizzes > 0 && users.length > 0 && quizzes.length > 0) {
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
		}
	}

	console.log(`✅ Data: ${quizzes.length} quizzes, ${questions.length} questions, ${posts.length} posts, ${allCommentsToInsert.length} comments`);
};

export const seedSpecificUsersContent = async (db: any, categoryMap?: Map<string, string>, seedImageUrls?: SeedImageUrls) => {
	if (SEED_USERS.length === 0) return;

	console.log(`📝 Creating content for ${SEED_USERS.length} seed users...`);

	const seedUserRecords = await db.select().from(schema.users).where(
		inArray(schema.users.email, SEED_USERS)
	);

	if (seedUserRecords.length === 0) {
		console.log('⚠️  No seed users found in database');
		return;
	}

	const categoryIds = categoryMap ? Array.from(categoryMap.values()) : [];
	const categoryIdToName = new Map<string, string>();
	if (categoryMap) {
		for (const [name, id] of categoryMap.entries()) {
			categoryIdToName.set(id, name);
		}
	}

	const categoryNameMap: Record<string, string> = {
		'General Knowledge': 'Kiến thức chung',
		'Science': 'Khoa học',
		'Math': 'Toán học',
		'History': 'Lịch sử',
		'Geography': 'Địa lý',
		'Literature': 'Văn học',
		'Music': 'Âm nhạc',
		'Movies': 'Phim ảnh',
		'Sports': 'Thể thao',
		'Technology': 'Công nghệ',
		'Programming': 'Lập trình',
		'Art': 'Nghệ thuật',
		'Other': 'Khác',
	};

	for (const user of seedUserRecords) {
		// Create collections
		for (let i = 0; i < SEED_COLLECTIONS_COUNT_PER_USER; i++) {
			const imageUrl = seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0
				? seedImageUrls.quizzes[i % seedImageUrls.quizzes.length]
				: null;

			await db.insert(schema.collections).values({
				userId: user.id,
				title: `Bộ sưu tập ${i + 1}`,
				description: `Các quiz yêu thích của ${user.fullName}`,
				imageUrl,
				quizCount: 0,
				isPublic: true,
			});
		}

		// Create quizzes with questions
		for (let i = 0; i < SEED_QUIZZES_COUNT_PER_USER; i++) {
			const categoryId = categoryIds.length > 0 ? categoryIds[i % categoryIds.length] : null;
			const englishCategoryName = categoryId ? categoryIdToName.get(categoryId) ?? 'General Knowledge' : 'General Knowledge';
			const vietnameseCategoryName = categoryNameMap[englishCategoryName] || 'Kiến thức chung';

			const imageUrl = seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0
				? seedImageUrls.quizzes[i % seedImageUrls.quizzes.length]
				: null;

			const [quiz] = await db.insert(schema.quizzes).values({
				userId: user.id,
				categoryId,
				title: generateQuizTitle(vietnameseCategoryName),
				description: generateQuizDescription(vietnameseCategoryName),
				imageUrl,
				questionCount: SEED_QUESTIONS_PER_QUIZ_COUNT,
				playCount: Math.floor(Math.random() * 5000),
				favoriteCount: Math.floor(Math.random() * 500),
				shareCount: Math.floor(Math.random() * 200),
				isPublic: true,
				questionsVisible: true,
				isDeleted: false,
				version: 1,
			}).returning();

			// Create questions for this quiz
			for (let j = 0; j < SEED_QUESTIONS_PER_QUIZ_COUNT; j++) {
				const questionType = questionTypes[j % questionTypes.length];
				await db.insert(schema.questions).values({
					quizId: quiz.id,
					type: questionType,
					questionText: generateQuestionText(vietnameseCategoryName, questionType, j),
					data: generateQuestionData(questionType),
					orderIndex: j,
				});
			}

			// Create quiz snapshot
			let snapshotId = null;
			for (let s = 0; s < SEED_QUIZ_SNAPSHOTS_COUNT_PER_QUIZ; s++) {
				const [snapshot] = await db.insert(schema.quizSnapshots).values({
					quizId: quiz.id,
					version: 1,
					title: quiz.title,
					description: quiz.description,
					questionCount: SEED_QUESTIONS_PER_QUIZ_COUNT,
				}).returning();

				if (s === 0) snapshotId = snapshot.id;

				// Create question snapshots
				for (let j = 0; j < SEED_QUESTIONS_PER_QUIZ_COUNT; j++) {
					const questionType = questionTypes[j % questionTypes.length];
					await db.insert(schema.questionsSnapshots).values({
						snapshotId: snapshot.id,
						type: questionType,
						questionText: generateQuestionText(vietnameseCategoryName, questionType, j),
						data: generateQuestionData(questionType),
						orderIndex: j,
					});
				}
			}

			// Create game sessions
			if (snapshotId) {
				for (let g = 0; g < SEED_GAME_SESSIONS_COUNT_PER_QUIZ; g++) {
					const randomCode = Math.random().toString(36).substring(2, 8).toUpperCase();
					await db.insert(schema.gameSessions).values({
						quizId: quiz.id,
						quizSnapshotId: snapshotId,
						hostId: user.id,
						title: quiz.title,
						estimatedMinutes: Math.floor(Math.random() * 56) + 5,
						isLive: false,
						joinedCount: Math.floor(Math.random() * 100),
						code: randomCode,
						quizVersion: 1,
					});
				}
			}
		}

		// Create posts
		for (let i = 0; i < SEED_POSTS_COUNT_PER_USER; i++) {
			const postType = ['text', 'text', 'text', 'image', 'quiz'][i % 5];
			let imageUrl = null;
			let questionType = null;
			let questionText = null;
			let questionData = null;

			if (postType === 'image') {
				imageUrl = seedImageUrls?.posts && seedImageUrls.posts.length > 0
					? seedImageUrls.posts[i % seedImageUrls.posts.length]
					: null;
			} else if (postType === 'quiz') {
				questionType = questionTypes[i % questionTypes.length];
				questionText = generateQuestionText(null, questionType, i);
				questionData = generateQuestionData(questionType);
			}

			await db.insert(schema.posts).values({
				userId: user.id,
				text: `Bài viết ${i + 1} từ ${user.fullName}`,
				postType,
				imageUrl,
				questionType,
				questionText,
				questionData,
				likesCount: Math.floor(Math.random() * 500),
				commentsCount: 0,
			});
		}

		console.log(`  ✓ Created content for ${user.email}`);
	}

	// Create follows between seed users and random users
	const allUsers = await db.select({ id: schema.users.id }).from(schema.users);
	for (const user of seedUserRecords) {
		const followCount = Math.min(SEED_FOLLOWS_COUNT_PER_USER, allUsers.length - 1);
		const usersToFollow = allUsers
			.filter(u => u.id !== user.id)
			.sort(() => Math.random() - 0.5)
			.slice(0, followCount);

		for (const toFollow of usersToFollow) {
			await db.insert(schema.follows).values({
				followerId: user.id,
				followingId: toFollow.id,
			}).onConflictDoNothing();
		}
	}

	console.log(`✅ Seed users content created`);
};
