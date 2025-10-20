import { sql } from 'drizzle-orm';

// Environment variables for excluded users
export const EXCLUDE_USERS = process.env.EXCLUDE_USERS?.split(',').map((email) => email.trim()) || [];

// Regular user seeding counts (for random users)
export const SEED_USERS_COUNT = Number(process.env.SEED_USERS_COUNT) || 50;
export const SEED_COLLECTIONS_COUNT = Number(process.env.SEED_COLLECTIONS_COUNT) || 30;
export const SEED_QUIZZES_COUNT = Number(process.env.SEED_QUIZZES_COUNT) || 100;
export const SEED_QUESTIONS_COUNT = Number(process.env.SEED_QUESTIONS_COUNT) || 500;
export const SEED_QUIZ_SNAPSHOTS_COUNT = Number(process.env.SEED_QUIZ_SNAPSHOTS_COUNT) || 150;
export const SEED_QUESTIONS_SNAPSHOTS_COUNT = Number(process.env.SEED_QUESTIONS_SNAPSHOTS_COUNT) || 750;
export const SEED_GAME_SESSIONS_COUNT = Number(process.env.SEED_GAME_SESSIONS_COUNT) || 200;
export const SEED_GAME_PARTICIPANTS_COUNT = Number(process.env.SEED_GAME_PARTICIPANTS_COUNT) || 1000;
export const SEED_SAVED_QUIZZES_COUNT = Number(process.env.SEED_SAVED_QUIZZES_COUNT) || 300;
export const SEED_POSTS_COUNT = Number(process.env.SEED_POSTS_COUNT) || 200;
export const SEED_POST_LIKES_COUNT = Number(process.env.SEED_POST_LIKES_COUNT) || 500;
export const SEED_COMMENTS_COUNT = Number(process.env.SEED_COMMENTS_COUNT) || 0;
export const SEED_COMMENT_LIKES_COUNT = Number(process.env.SEED_COMMENT_LIKES_COUNT) || 0;
export const SEED_FOLLOWS_COUNT = Number(process.env.SEED_FOLLOWS_COUNT) || 500;
export const SEED_NOTIFICATIONS_COUNT = Number(process.env.SEED_NOTIFICATIONS_COUNT) || 1000;

// Excluded user seeding counts (per-excluded-user)
export const SEED_EXCLUDED_COLLECTIONS_PER_USER = Number(process.env.SEED_EXCLUDED_COLLECTIONS_PER_USER) || 5;
export const SEED_EXCLUDED_QUIZZES_PER_USER = Number(process.env.SEED_EXCLUDED_QUIZZES_PER_USER) || 10;
export const SEED_EXCLUDED_QUESTIONS_PER_QUIZ = Number(process.env.SEED_EXCLUDED_QUESTIONS_PER_QUIZ) || 8;
export const SEED_EXCLUDED_GAME_SESSIONS_PER_USER = Number(process.env.SEED_EXCLUDED_GAME_SESSIONS_PER_USER) || 3;
export const SEED_EXCLUDED_PARTICIPANTS_PER_SESSION = Number(process.env.SEED_EXCLUDED_PARTICIPANTS_PER_SESSION) || 15;
export const SEED_EXCLUDED_SAVED_QUIZZES_PER_USER = Number(process.env.SEED_EXCLUDED_SAVED_QUIZZES_PER_USER) || 20;
export const SEED_EXCLUDED_POSTS_PER_USER = Number(process.env.SEED_EXCLUDED_POSTS_PER_USER) || 15;
export const SEED_EXCLUDED_FOLLOWERS_PER_USER = Number(process.env.SEED_EXCLUDED_FOLLOWERS_PER_USER) || 25;
export const SEED_EXCLUDED_FOLLOWING_PER_USER = Number(process.env.SEED_EXCLUDED_FOLLOWING_PER_USER) || 20;
export const SEED_EXCLUDED_NOTIFICATIONS_PER_USER = Number(process.env.SEED_EXCLUDED_NOTIFICATIONS_PER_USER) || 30;

// Data generation constants
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
	'multiple_choice',
	'true_false',
	'single_answer',
	'reorder',
	'type_answer',
	'drop_pin',
];

export const accountTypes = ['student', 'teacher', 'professional'];

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

// Helper functions for generating specific data
export const generateQuestionData = (type: string) => {
	const baseData = {
		// randomize time limit and points within sensible bounds
		timeLimit: 15 + Math.floor(Math.random() * 46), // 15-60 seconds
		points: [50, 100, 150][Math.floor(Math.random() * 3)],
		explanation: 'This question tests your understanding of the topic.',
	};
	
	switch (type) {
		case 'multiple_choice':
			return {
				...baseData,
				options: [
					{ text: 'Option A', isCorrect: false },
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
		case 'single_answer':
			return {
				...baseData,
				correctAnswer: 'Sample Answer',
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
		case 'type_answer':
			return {
				...baseData,
				correctAnswer: 'type this answer',
				caseSensitive: false,
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
		case 'multiple_choice':
			return `(${index + 1}) Which statement about ${base} is correct?`;
		case 'true_false':
			return `(${index + 1}) True or False: A common fact in ${base}.`;
		case 'single_answer':
			return `(${index + 1}) Briefly answer this ${base} question.`;
		case 'reorder':
			return `(${index + 1}) Arrange these ${base} steps in order.`;
		case 'type_answer':
			return `(${index + 1}) Type the correct term from ${base}.`;
		case 'drop_pin':
			return `(${index + 1}) Locate the relevant place related to ${base}.`;
		default:
			return `(${index + 1}) Question about ${base}.`;
	}
};

export const generatePostContent = (category: string) => {
	const templates = [
		`Just completed an amazing ${category} quiz! Really tested my knowledge.`,
		`Anyone interested in studying ${category} together? I've created a new collection.`,
		`Discovered some fascinating facts about ${category} today. Learning never stops!`,
		`My ${category} challenge is live! Who's ready to test their skills?`,
		`Created a comprehensive ${category} study guide. Hope it helps everyone!`,
	];
	return templates[Math.floor(Math.random() * templates.length)];
};

export const generateNotificationTitle = (type: string) => {
	switch (type) {
		case 'like':
			return 'Someone liked your post';
		case 'comment':
			return 'New comment on your quiz';
		case 'follow':
			return 'You have a new follower';
		case 'quiz_share':
			return 'Someone shared your quiz';
		case 'game_invite':
			return 'You were invited to a game';
		default:
			return 'New notification';
	}
};

export const generateNotificationSubtitle = (type: string) => {
	switch (type) {
		case 'like':
			return 'Your post is getting popular!';
		case 'comment':
			return 'Check out what they said';
		case 'follow':
			return 'See who\'s following you';
		case 'quiz_share':
			return 'Your quiz is being shared';
		case 'game_invite':
			return 'Join the fun';
		default:
			return 'Click to view details';
	}
};

// Calculate derived counts for excluded users
export const calculateDerivedCounts = (excludedUserIds: string[]) => {
	return {
		collections: excludedUserIds.length * SEED_EXCLUDED_COLLECTIONS_PER_USER,
		quizzes: excludedUserIds.length * SEED_EXCLUDED_QUIZZES_PER_USER,
		questions: excludedUserIds.length * SEED_EXCLUDED_QUIZZES_PER_USER * SEED_EXCLUDED_QUESTIONS_PER_QUIZ,
		gameSessions: excludedUserIds.length * SEED_EXCLUDED_GAME_SESSIONS_PER_USER,
		gameParticipants: excludedUserIds.length * SEED_EXCLUDED_GAME_SESSIONS_PER_USER * SEED_EXCLUDED_PARTICIPANTS_PER_SESSION,
		savedQuizzes: excludedUserIds.length * SEED_EXCLUDED_SAVED_QUIZZES_PER_USER,
		posts: excludedUserIds.length * SEED_EXCLUDED_POSTS_PER_USER,
		follows: excludedUserIds.length * (SEED_EXCLUDED_FOLLOWERS_PER_USER + SEED_EXCLUDED_FOLLOWING_PER_USER),
		notifications: excludedUserIds.length * SEED_EXCLUDED_NOTIFICATIONS_PER_USER,
	};
};

