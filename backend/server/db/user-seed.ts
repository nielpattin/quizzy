import { sql, eq } from 'drizzle-orm';
import * as schema from './schema';
import {
	SEED_EXCLUDED_COLLECTIONS_PER_USER,
	SEED_EXCLUDED_QUIZZES_PER_USER,
	SEED_EXCLUDED_QUESTIONS_PER_QUIZ,
	SEED_EXCLUDED_GAME_SESSIONS_PER_USER,
	SEED_EXCLUDED_PARTICIPANTS_PER_SESSION,
	SEED_EXCLUDED_SAVED_QUIZZES_PER_USER,
	SEED_EXCLUDED_POSTS_PER_USER,
	SEED_EXCLUDED_FOLLOWERS_PER_USER,
	SEED_EXCLUDED_FOLLOWING_PER_USER,
	SEED_EXCLUDED_NOTIFICATIONS_PER_USER,
	categories,
	questionTypes,
	notificationTypes,
	generateQuestionData,
	generatePostContent,
	generateNotificationTitle,
	generateNotificationSubtitle,
	type SeedImageUrls,
} from './config-seed';

export const seedExcludedUsers = async (
	db: any,
	excludedUserIds: string[],
	seedImageUrls?: SeedImageUrls,
) => {
	console.log('\n🔒 Generating guaranteed data for excluded users...');
	
	for (const userId of excludedUserIds) {
		
		// Generate collections for excluded user
		const userCollections = [];
		for (let i = 0; i < SEED_EXCLUDED_COLLECTIONS_PER_USER; i++) {
			const collectionData = {
				userId,
				title: `${categories[i % categories.length]} Collection ${i + 1}`,
				description: `Comprehensive ${categories[i % categories.length]} collection for study and practice`,
				quizCount: Math.floor(Math.random() * 10) + 5,
				isPublic: Math.random() > 0.3,
			};
			const [collection] = await db.insert(schema.collections).values(collectionData).returning();
			userCollections.push(collection);
		}
		
		// Generate quizzes for excluded user
		const userQuizzes = [];
		for (let i = 0; i < SEED_EXCLUDED_QUIZZES_PER_USER; i++) {
			const randomCollection = userCollections[Math.floor(Math.random() * userCollections.length)];
			const questionCount = Math.floor(Math.random() * 15) + 5;
			const quizData = {
				userId,
				collectionId: randomCollection.id,
				title: `${categories[i % categories.length]} Challenge ${i + 1}`,
				description: `Test your knowledge of ${categories[i % categories.length]} with this comprehensive quiz`,
				category: categories[i % categories.length],
				questionCount,
				playCount: Math.floor(Math.random() * 1000) + 50,
				favoriteCount: Math.floor(Math.random() * 100) + 10,
				shareCount: Math.floor(Math.random() * 50) + 5,
				isPublic: Math.random() > 0.2,
				questionsVisible: true,
				isDeleted: false,
				version: 1,
			};
			const [quiz] = await db.insert(schema.quizzes).values(quizData).returning();
			userQuizzes.push(quiz);
			
			// Generate questions for this quiz
			for (let j = 0; j < questionCount; j++) {
				const questionType = questionTypes[j % questionTypes.length];
				const questionData = {
					quizId: quiz.id,
					type: questionType as any,
					questionText: `Question ${j + 1} about ${categories[i % categories.length]}`,
					data: generateQuestionData(questionType),
					orderIndex: j,
				};
				await db.insert(schema.questions).values(questionData);
			}
		}
		
		// Generate game sessions hosted by excluded user
		for (let i = 0; i < SEED_EXCLUDED_GAME_SESSIONS_PER_USER; i++) {
			const randomQuiz = userQuizzes[Math.floor(Math.random() * userQuizzes.length)];
			
			// First create a quiz snapshot for the game session
			const snapshotData = {
				quizId: randomQuiz.id,
				version: randomQuiz.version,
				title: randomQuiz.title,
				description: randomQuiz.description,
				category: randomQuiz.category,
				questionCount: randomQuiz.questionCount,
			};
			const [snapshot] = await db.insert(schema.quizSnapshots).values(snapshotData).returning();
			
			// Copy questions from quiz to snapshot
			const quizQuestions = await db
				.select()
				.from(schema.questions)
				.where(eq(schema.questions.quizId, randomQuiz.id))
				.orderBy(schema.questions.orderIndex);
			
			if (quizQuestions.length > 0) {
				const snapshotQuestions = quizQuestions.map((q: any) => ({
					snapshotId: snapshot.id,
					type: q.type,
					questionText: q.questionText,
					data: q.data,
					orderIndex: q.orderIndex,
				}));
				await db.insert(schema.questionsSnapshots).values(snapshotQuestions);
			}
			
			const sessionData = {
				hostId: userId,
				quizSnapshotId: snapshot.id,
				title: `${randomQuiz.title} - Game Session ${i + 1}`,
				estimatedMinutes: randomQuiz.questionCount * 2,
				isLive: false,
				joinedCount: 0,
				code: `GAME${Math.random().toString(36).substring(2, 8).toUpperCase()}`,
				quizVersion: randomQuiz.version,
				startedAt: null,
				endedAt: null,
			};
			const [session] = await db.insert(schema.gameSessions).values(sessionData).returning();
			
			// Generate participants for this session
			const participantCount = Math.floor(Math.random() * SEED_EXCLUDED_PARTICIPANTS_PER_SESSION) + 1;
			for (let j = 0; j < participantCount; j++) {
				const participantData = {
					sessionId: session.id,
					userId: j === 0 ? userId : null, // Host is first participant
					score: Math.floor(Math.random() * 10000),
					rank: j + 1,
					joinedAt: new Date(),
					leftAt: Math.random() > 0.3 ? new Date() : null,
				};
				await db.insert(schema.gameSessionParticipants).values(participantData);
			}
		}
		
		// Generate saved quizzes for excluded user
		for (let i = 0; i < SEED_EXCLUDED_SAVED_QUIZZES_PER_USER; i++) {
			const randomQuiz = userQuizzes[Math.floor(Math.random() * userQuizzes.length)];
			
			// Create quiz snapshot for saved quiz
			const snapshotData = {
				quizId: randomQuiz.id,
				version: randomQuiz.version,
				title: randomQuiz.title,
				description: randomQuiz.description,
				category: randomQuiz.category,
				questionCount: randomQuiz.questionCount,
			};
			const [snapshot] = await db.insert(schema.quizSnapshots).values(snapshotData).returning();
			
			// Copy questions from quiz to snapshot
			const quizQuestions = await db
				.select()
				.from(schema.questions)
				.where(eq(schema.questions.quizId, randomQuiz.id))
				.orderBy(schema.questions.orderIndex);
			
			if (quizQuestions.length > 0) {
				const snapshotQuestions = quizQuestions.map((q: any) => ({
					snapshotId: snapshot.id,
					type: q.type,
					questionText: q.questionText,
					data: q.data,
					orderIndex: q.orderIndex,
				}));
				await db.insert(schema.questionsSnapshots).values(snapshotQuestions);
			}
			
			const savedQuizData = {
				userId,
				quizSnapshotId: snapshot.id,
				savedAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000), // Random within last 30 days
			};
			await db.insert(schema.savedQuizzes).values(savedQuizData);
		}
		
		// Generate posts for excluded user
		for (let i = 0; i < SEED_EXCLUDED_POSTS_PER_USER; i++) {
			const postTypeRand = Math.random();
			let postType: 'text' | 'image' | 'quiz' = 'text';
			let questionType = null;
			let questionText = null;
			let questionData = null;
			let imageUrl = null;
			
			if (postTypeRand < 0.3) {
				postType = 'quiz';
				const qTypes = ['single_choice', 'checkbox', 'true_false'];
				questionType = qTypes[Math.floor(Math.random() * qTypes.length)] as any;
				questionText = `Quick quiz: ${generatePostContent(categories[i % categories.length])}`;
				questionData = generateQuestionData(questionType);
				
				if (seedImageUrls?.quizzes && seedImageUrls.quizzes.length > 0 && Math.random() < 0.3) {
					imageUrl = seedImageUrls.quizzes[i % seedImageUrls.quizzes.length];
				}
			} else if (postTypeRand < 0.5) {
				postType = 'image';
				if (seedImageUrls?.posts && seedImageUrls.posts.length > 0) {
					imageUrl = seedImageUrls.posts[i % seedImageUrls.posts.length];
				}
			}
			
			const postData = {
				userId,
				text: generatePostContent(categories[i % categories.length]),
				postType,
				imageUrl,
				questionType,
				questionText,
				questionData,
				answersCount: postType === 'quiz' ? Math.floor(Math.random() * 50) : 0,
				likesCount: Math.floor(Math.random() * 100),
				commentsCount: 0,
				createdAt: new Date(Date.now() - Math.random() * 60 * 24 * 60 * 60 * 1000),
			};
			await db.insert(schema.posts).values(postData);
		}
		
		// Generate follows (followers and following) for excluded user
		// Get other users from database to create realistic follows
		const otherUsers = await db
			.select({ id: schema.users.id })
			.from(schema.users)
			.where(sql`${schema.users.id} != ${userId}`)
			.limit(Math.max(SEED_EXCLUDED_FOLLOWERS_PER_USER, SEED_EXCLUDED_FOLLOWING_PER_USER));
		
		// Generate followers
		if (otherUsers.length > 0) {
			for (let i = 0; i < Math.min(SEED_EXCLUDED_FOLLOWERS_PER_USER, otherUsers.length); i++) {
				const followData = {
					followerId: otherUsers[i % otherUsers.length].id,
					followingId: userId,
					createdAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000),
				};
				await db.insert(schema.follows).values(followData);
			}
			
			// Generate following
			for (let i = 0; i < Math.min(SEED_EXCLUDED_FOLLOWING_PER_USER, otherUsers.length); i++) {
				const followData = {
					followerId: userId,
					followingId: otherUsers[(i + 1) % otherUsers.length].id, // Offset to avoid self-follow
					createdAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000),
				};
				await db.insert(schema.follows).values(followData);
			}
		}
		
		// Generate notifications for excluded user
		for (let i = 0; i < SEED_EXCLUDED_NOTIFICATIONS_PER_USER; i++) {
			const notificationType = notificationTypes[i % notificationTypes.length];
			const notificationData = {
				userId,
				type: notificationType,
				title: generateNotificationTitle(notificationType),
				subtitle: generateNotificationSubtitle(notificationType),
				isUnread: Math.random() > 0.6,
				createdAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000), // Random within last week
			};
			await db.insert(schema.notifications).values(notificationData);
		}
	}
	
	console.log('✅ Excluded user data generation completed');
};