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

export const questionTypes: string[] = [
	'single_choice',
	'checkbox',
	'true_false',
	'type_answer',
	'reorder',
	'drop_pin',
];

export const accountTypes = ['user', 'employee', 'admin'];

export const bios = [
	'Quiz enthusiast and educator',
	'Learning something new every day 📚',
	'Creating engaging educational content',
	'Passionate about knowledge sharing',
	'Making learning fun for everyone',
	'Teacher by day, quiz creator by night',
	'Building better learning experiences',
	'Education technology advocate',
];

export const notificationTypes = ['like', 'comment', 'follow', 'quiz_share', 'game_invite'];

export const generateQuestionData = (type: string) => {
	const baseData = {
		timeLimit: 15 + Math.floor(Math.random() * 46),
		points: [50, 100, 150][Math.floor(Math.random() * 3)],
		explanation: 'This question tests your understanding of the topic.',
	};
	
	switch (type) {
		case 'single_choice':
			return {
				...baseData,
				options: [
					{ text: 'Option A', isCorrect: false },
					{ text: 'Option B', isCorrect: true },
					{ text: 'Option C', isCorrect: false },
					{ text: 'Option D', isCorrect: false },
				],
			};
		case 'checkbox':
			return {
				...baseData,
				options: [
					{ text: 'Option A', isCorrect: true },
					{ text: 'Option B', isCorrect: true },
					{ text: 'Option C', isCorrect: false },
					{ text: 'Option D', isCorrect: false },
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
				correctAnswer: 'type this answer',
				caseSensitive: false,
			};
		case 'reorder':
			return {
				...baseData,
				items: [
					{ id: 1, text: 'First item', correctOrder: 0 },
					{ id: 2, text: 'Second item', correctOrder: 1 },
					{ id: 3, text: 'Third item', correctOrder: 2 },
				],
			};
		case 'drop_pin':
			return {
				...baseData,
				correctLocation: { lat: 40.7128, lng: -74.0060 },
				tolerance: 0.1,
			};
		default:
			return baseData;
	}
};

export const generateQuizTitle = (category: string) => {
	const templates = [
		`${category} Essentials`,
		`Mastering ${category}`,
		`${category} Fundamentals`,
		`${category} Challenge`,
		`Intro to ${category}`,
	];
	return templates[Math.floor(Math.random() * templates.length)];
};

export const generateQuizDescription = (category: string) => {
	const templates = [
		`Test your core knowledge of ${category} with balanced difficulty questions.`,
		`A curated set of ${category} questions to help you practice effectively.`,
		`Explore key concepts in ${category} with clear, focused questions.`,
		`Sharpen your ${category} skills with this engaging quiz.`,
	];
	return templates[Math.floor(Math.random() * templates.length)];
};

export const generateQuestionText = (category: string | null, type: string, index: number) => {
	const base = category ?? 'General Knowledge';
	switch (type) {
		case 'single_choice':
			return `(${index + 1}) Which statement about ${base} is correct?`;
		case 'checkbox':
			return `(${index + 1}) Select all that apply for ${base}.`;
		case 'true_false':
			return `(${index + 1}) True or False: A common fact in ${base}.`;
		case 'type_answer':
			return `(${index + 1}) Type the correct term from ${base}.`;
		case 'reorder':
			return `(${index + 1}) Arrange these ${base} steps in order.`;
		case 'drop_pin':
			return `(${index + 1}) Locate the relevant place related to ${base}.`;
		default:
			return `(${index + 1}) Question about ${base}.`;
	}
};

export interface SeedImageUrls {
	posts: string[];
	quizzes: string[];
	profiles: string[];
}

export const FIXED_USERS: Array<typeof schema.users.$inferInsert> = [
  {
    email: 'alice@quizzy.dev',
    fullName: 'Alice Johnson',
    username: 'alice',
    bio: 'Curates quality quizzes and study packs',
    accountType: 'employee',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000001?v=4',
  },
  {
    email: 'bob@quizzy.dev',
    fullName: 'Bob Martinez',
    username: 'bmart',
    bio: 'Learning something new every day',
    accountType: 'user',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000002?v=4',
  },
  {
    email: 'carol@quizzy.dev',
    fullName: 'Carol Nguyen',
    username: 'caroln',
    bio: 'Making learning fun for everyone',
    accountType: 'employee',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000003?v=4',
  },
  {
    email: 'dave@quizzy.dev',
    fullName: 'Dave Patel',
    username: 'davep',
    bio: 'Quiz enthusiast and educator',
    accountType: 'admin',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000004?v=4',
  },
  {
    email: 'eve@quizzy.dev',
    fullName: 'Eve Walker',
    username: 'evew',
    bio: 'Creating engaging educational content',
    accountType: 'user',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000005?v=4',
  },
  {
    email: 'frank@quizzy.dev',
    fullName: 'Frank Zhao',
    username: 'frankz',
    bio: 'Building better learning experiences',
    accountType: 'admin',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000006?v=4',
  },
];

export const FIXED_USER_COLLECTIONS = [
  { email: 'alice@quizzy.dev', collections: [
    { title: 'Science Study Pack', description: 'Comprehensive science resources for students' },
    { title: 'History Collection', description: 'Key events and timelines in world history' },
    { title: 'Math Essentials', description: 'Core mathematics concepts and practice' }
  ]},
  { email: 'bob@quizzy.dev', collections: [
    { title: 'My Favorites', description: 'Quizzes I enjoy practicing' },
    { title: 'Study Group', description: 'Shared quizzes with classmates' }
  ]},
  { email: 'carol@quizzy.dev', collections: [
    { title: 'Literature Collection', description: 'Classic and modern literature studies' },
    { title: 'Art & Music', description: 'Creative arts exploration' }
  ]},
  { email: 'dave@quizzy.dev', collections: [
    { title: 'Business Essentials', description: 'Core business concepts and strategies' },
    { title: 'Technology Trends', description: 'Latest in tech and innovation' }
  ]},
  { email: 'eve@quizzy.dev', collections: [
    { title: 'Practice Quizzes', description: 'Daily practice and review materials' }
  ]},
  { email: 'frank@quizzy.dev', collections: [
    { title: 'Professional Development', description: 'Career growth and skill building' },
    { title: 'Skills Training', description: 'Hands-on technical training resources' }
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
