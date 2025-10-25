import * as schema from './schema';

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

export const categories = [
	'Khoa học',
	'Lịch sử',
	'Địa lý',
	'Toán học',
	'Văn học',
	'Công nghệ',
	'Thể thao',
	'Âm nhạc',
	'Nghệ thuật',
	'Kinh doanh',
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
