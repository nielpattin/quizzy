import * as schema from './schema';
import { eq, desc } from 'drizzle-orm';

// A small set of canonical users that always exist
// Safe to run multiple times thanks to onConflictDoNothing on email
export const FIXED_USERS: Array<typeof schema.users.$inferInsert> = [
  {
    email: 'alice@quizzy.dev',
    fullName: 'Alice Johnson',
    username: 'alice',
    bio: 'Curates quality quizzes and study packs',
    accountType: 'teacher',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000001?v=4',
  },
  {
    email: 'bob@quizzy.dev',
    fullName: 'Bob Martinez',
    username: 'bmart',
    bio: 'Learning something new every day',
    accountType: 'student',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000002?v=4',
  },
  {
    email: 'carol@quizzy.dev',
    fullName: 'Carol Nguyen',
    username: 'caroln',
    bio: 'Making learning fun for everyone',
    accountType: 'teacher',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000003?v=4',
  },
  {
    email: 'dave@quizzy.dev',
    fullName: 'Dave Patel',
    username: 'davep',
    bio: 'Quiz enthusiast and educator',
    accountType: 'professional',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000004?v=4',
  },
  {
    email: 'eve@quizzy.dev',
    fullName: 'Eve Walker',
    username: 'evew',
    bio: 'Creating engaging educational content',
    accountType: 'student',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000005?v=4',
  },
  {
    email: 'frank@quizzy.dev',
    fullName: 'Frank Zhao',
    username: 'frankz',
    bio: 'Building better learning experiences',
    accountType: 'professional',
    isSetupComplete: true,
    profilePictureUrl: 'https://avatars.githubusercontent.com/u/000006?v=4',
  },
];

const FIXED_USER_COLLECTIONS = [
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

export const seedFixedUsers = async (db: any) => {
  // Ensure deterministic ordering
  for (const u of FIXED_USERS) {
    await db
      .insert(schema.users)
      .values({
        email: u.email,
        fullName: u.fullName,
        username: u.username,
        bio: u.bio,
        accountType: u.accountType ?? 'student',
        isSetupComplete: u.isSetupComplete ?? true,
        profilePictureUrl: u.profilePictureUrl,
      })
      .onConflictDoNothing({ target: schema.users.email });
  }
};

export const seedFixedUsersData = async (db: any) => {
  console.log('🔧 Seeding collections and saved quizzes for fixed users...');

  for (const fixedUserConfig of FIXED_USER_COLLECTIONS) {
    const [user] = await db
      .select()
      .from(schema.users)
      .where(eq(schema.users.email, fixedUserConfig.email));

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
        await db
          .update(schema.quizzes)
          .set({ collectionId: newCollection.id })
          .where(eq(schema.quizzes.id, quiz.id));
        addedCount++;
      }

      await db
        .update(schema.collections)
        .set({ quizCount: addedCount })
        .where(eq(schema.collections.id, newCollection.id));
    }

    const availableSnapshots = await db
      .select()
      .from(schema.quizSnapshots)
      .orderBy(desc(schema.quizSnapshots.createdAt))
      .limit(8);

    for (const snapshot of availableSnapshots) {
      await db
        .insert(schema.savedQuizzes)
        .values({
          userId: user.id,
          quizSnapshotId: snapshot.id,
        })
        .onConflictDoNothing();
    }
  }

  console.log('✅ Fixed users collections and saved quizzes seeded');
};
