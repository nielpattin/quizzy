import { pgTable, text, timestamp, uuid, boolean, varchar, date, integer, jsonb, index, foreignKey, pgEnum, unique } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

export const questionTypeEnum = pgEnum('question_type', [
  'single_choice',
  'checkbox',
  'true_false',
  'type_answer',
  'reorder',
  'drop_pin',
]);

export const postTypeEnum = pgEnum('post_type', ['text', 'image', 'quiz']);

export const moderationStatusEnum = pgEnum('moderation_status', ['approved', 'flagged', 'rejected', 'review_pending']);

export const accountTypeEnum = pgEnum('account_type', ['admin', 'employee', 'user']);

export const statusEnum = pgEnum('status', ['active', 'inactive']);

export const searchFilterTypeEnum = pgEnum('search_filter_type', ['quiz', 'user', 'collection', 'post']);

export const notificationTypeEnum = pgEnum('notification_type', [
  'like',
  'comment',
  'follow',
  'quiz_share',
  'game_invite',
  'mention',
  'quiz_answer',
  'follow_request',
  'system'
]);

export const logLevelEnum = pgEnum('log_level', ['error', 'warn', 'info', 'debug', 'trace']);

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  fullName: text('full_name').notNull().default(''),
  username: varchar('username', { length: 50 }).unique(),
  dob: date('dob'),
  bio: text('bio'),
  profilePictureUrl: text('profile_picture_url'),
  accountType: accountTypeEnum('account_type').notNull().default('user'),
  status: statusEnum('status').notNull().default('active'),
  isSetupComplete: boolean('is_setup_complete').notNull().default(false),
  followersCount: integer('followers_count').notNull().default(0),
  followingCount: integer('following_count').notNull().default(0),
  lastLoginAt: timestamp('last_login_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('users_email_idx').on(table.email),
  index('users_username_idx').on(table.username),
]);

export const categories = pgTable('categories', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull().unique(),
  slug: text('slug').notNull().unique(),
  description: text('description'),
  imageUrl: text('image_url'),
}, (table) => [
  index('categories_slug_idx').on(table.slug),
]);

export const collections = pgTable('collections', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  title: text('title').notNull(),
  description: text('description'),
  imageUrl: text('image_url'),
  quizCount: integer('quiz_count').notNull().default(0),
  isPublic: boolean('is_public').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('collections_user_id_idx').on(table.userId),
]);

export const quizzes = pgTable('quizzes', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  collectionId: uuid('collection_id').references(() => collections.id, { onDelete: 'set null' }),
  categoryId: uuid('category_id').references(() => categories.id, { onDelete: 'set null' }),
  title: text('title').notNull(),
  description: text('description'),
  imageUrl: text('image_url'),
  questionCount: integer('question_count').notNull().default(0),
  playCount: integer('play_count').notNull().default(0),
  favoriteCount: integer('favorite_count').notNull().default(0),
  shareCount: integer('share_count').notNull().default(0),
  isPublic: boolean('is_public').notNull().default(true),
  questionsVisible: boolean('questions_visible').notNull().default(false),
  isDeleted: boolean('is_deleted').notNull().default(false), // For soft deletion
  deletedAt: timestamp('deleted_at', { withTimezone: true }), // Timestamp for when the quiz was soft deleted
  version: integer('version').notNull().default(1), // Versioning for quizzes
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('quizzes_user_id_idx').on(table.userId),
  index('quizzes_collection_id_idx').on(table.collectionId),
  index('quizzes_category_id_idx').on(table.categoryId),
  index('quizzes_is_deleted_idx').on(table.isDeleted),
]);

export const questions = pgTable('questions', {
  id: uuid('id').primaryKey().defaultRandom(),
  quizId: uuid('quiz_id').notNull().references(() => quizzes.id, { onDelete: 'cascade' }),
  type: questionTypeEnum('type').notNull(),
  questionText: text('question_text').notNull(),
  imageUrl: text('image_url'),
  data: jsonb('data').notNull().$type<Record<string, any>>(),
  orderIndex: integer('order_index').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('questions_quiz_id_idx').on(table.quizId),
  index('questions_type_idx').on(table.type),
]);

export const questionsSnapshots = pgTable('questions_snapshots', {
  id: uuid('id').primaryKey().defaultRandom(),
  snapshotId: uuid('snapshot_id').notNull().references(() => quizSnapshots.id, { onDelete: 'cascade' }),
  type: questionTypeEnum('type').notNull(),
  questionText: text('question_text').notNull(),
  imageUrl: text('image_url'),
  data: jsonb('data').notNull().$type<Record<string, any>>(),
  orderIndex: integer('order_index').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('questions_snapshots_snapshot_id_idx').on(table.snapshotId),
  index('questions_snapshots_order_index_idx').on(table.orderIndex),
  index('questions_snapshots_type_idx').on(table.type),
]);

export const quizSnapshots = pgTable('quiz_snapshots', {
  id: uuid('id').primaryKey().defaultRandom(),
  quizId: uuid('quiz_id').notNull().references(() => quizzes.id, { onDelete: 'restrict' }),
  version: integer('version').notNull(),
  title: text('title').notNull(),
  description: text('description'),
  questionCount: integer('question_count').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('quiz_snapshots_quiz_id_idx').on(table.quizId),
  index('quiz_snapshots_version_idx').on(table.version),
  index('quiz_snapshots_quiz_id_version_idx').on(table.quizId, table.version),
]);

export const gameSessions = pgTable('game_sessions', {
  id: uuid('id').primaryKey().defaultRandom(),
  hostId: uuid('host_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  quizSnapshotId: uuid('quiz_snapshot_id').notNull().references(() => quizSnapshots.id, { onDelete: 'restrict' }),
  title: text('title').notNull(),
  estimatedMinutes: integer('estimated_minutes').notNull(),
  isLive: boolean('is_live').notNull().default(false),
  joinedCount: integer('joined_count').notNull().default(0),
  code: varchar('code', { length: 10 }).unique(),
  quizVersion: integer('quiz_version').notNull(),
  startedAt: timestamp('started_at', { withTimezone: true }),
  endedAt: timestamp('ended_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('game_sessions_host_id_idx').on(table.hostId),
  index('game_sessions_quiz_snapshot_id_idx').on(table.quizSnapshotId),
  index('game_sessions_code_idx').on(table.code),
  index('game_sessions_is_live_idx').on(table.isLive),
  index('game_sessions_quiz_version_idx').on(table.quizVersion),
]);

export const gameSessionParticipants = pgTable('game_session_participants', {
  id: uuid('id').primaryKey().defaultRandom(),
  sessionId: uuid('session_id').notNull().references(() => gameSessions.id, { onDelete: 'cascade' }),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  score: integer('score').notNull().default(0),
  rank: integer('rank'),
  joinedAt: timestamp('joined_at', { withTimezone: true }).defaultNow().notNull(),
  leftAt: timestamp('left_at', { withTimezone: true }),
}, (table) => [
  index('game_session_participants_session_id_idx').on(table.sessionId),
  index('game_session_participants_user_id_idx').on(table.userId),
]);

export const favoriteQuizzes = pgTable('favorite_quizzes', {
   id: uuid('id').primaryKey().defaultRandom(),
   userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
   quizId: uuid('quiz_id').notNull().references(() => quizzes.id, { onDelete: 'cascade' }),
   favoritedAt: timestamp('favorited_at', { withTimezone: true }).defaultNow().notNull(),
 }, (table) => [
   index('favorite_quizzes_user_id_idx').on(table.userId),
   index('favorite_quizzes_quiz_id_idx').on(table.quizId),
   unique('favorite_quizzes_user_quiz_unique').on(table.userId, table.quizId),
 ]);

export const postLikes = pgTable('post_likes', {
   id: uuid('id').primaryKey().defaultRandom(),
   userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
   postId: uuid('post_id').notNull().references(() => posts.id, { onDelete: 'cascade' }),
   createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
 }, (table) => [
   index('post_likes_user_id_idx').on(table.userId),
   index('post_likes_post_id_idx').on(table.postId),
   index('post_likes_user_id_post_id_idx').on(table.userId, table.postId),
 ]);

export const postAnswers = pgTable('post_answers', {
  id: uuid('id').primaryKey().defaultRandom(),
  postId: uuid('post_id').notNull().references(() => posts.id, { onDelete: 'cascade' }),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  answer: jsonb('answer').notNull(),
  isCorrect: boolean('is_correct').notNull(),
  answeredAt: timestamp('answered_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('post_answers_post_id_idx').on(table.postId),
  index('post_answers_user_id_idx').on(table.userId),
  index('post_answers_post_id_user_id_idx').on(table.postId, table.userId),
]);

export const comments = pgTable('comments', {
   id: uuid('id').primaryKey().defaultRandom(),
   postId: uuid('post_id').notNull().references(() => posts.id, { onDelete: 'cascade' }),
   userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
   content: text('content').notNull(),
   likesCount: integer('likes_count').notNull().default(0),
   createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
   updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
 }, (table) => [
   index('comments_post_id_idx').on(table.postId),
   index('comments_user_id_idx').on(table.userId),
   index('comments_created_at_idx').on(table.createdAt),
 ]);

export const commentLikes = pgTable('comment_likes', {
   id: uuid('id').primaryKey().defaultRandom(),
   userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
   commentId: uuid('comment_id').notNull().references(() => comments.id, { onDelete: 'cascade' }),
   createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
 }, (table) => [
   index('comment_likes_user_id_idx').on(table.userId),
   index('comment_likes_comment_id_idx').on(table.commentId),
   index('comment_likes_user_id_comment_id_idx').on(table.userId, table.commentId),
 ]);

export const commentLikesRelations = relations(commentLikes, ({ one }) => ({
   user: one(users, {
     fields: [commentLikes.userId],
     references: [users.id],
   }),
   comment: one(comments, {
     fields: [commentLikes.commentId],
     references: [comments.id],
   }),
 }));

export const images = pgTable('images', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  filename: text('filename').notNull().unique(),
  originalName: text('original_name').notNull(),
  mimeType: text('mime_type').notNull(),
  size: integer('size').notNull(),
  bucket: text('bucket').notNull().default('quiz-images'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('images_user_id_idx').on(table.userId),
  index('images_filename_idx').on(table.filename),
  index('images_created_at_idx').on(table.createdAt),
]);

export type Image = typeof images.$inferSelect;
export type InsertImage = typeof images.$inferInsert;

export const posts = pgTable('posts', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  text: text('text').notNull(),
  postType: postTypeEnum('post_type').notNull().default('text'),
  imageUrl: text('image_url'),
  questionType: questionTypeEnum('question_type'),
  questionText: text('question_text'),
  questionData: jsonb('question_data').$type<{ options: string[], correctAnswer: number | number[] }>(),
  answersCount: integer('answers_count').notNull().default(0),
  likesCount: integer('likes_count').notNull().default(0),
  commentsCount: integer('comments_count').notNull().default(0),
  moderationStatus: moderationStatusEnum('moderation_status').notNull().default('approved'),
  moderatedBy: uuid('moderated_by').references(() => users.id, { onDelete: 'set null' }),
  moderatedAt: timestamp('moderated_at', { withTimezone: true }),
  flagCount: integer('flag_count').notNull().default(0),
  flagReasons: jsonb('flag_reasons').$type<string[]>().default([]),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('posts_user_id_idx').on(table.userId),
  index('posts_created_at_idx').on(table.createdAt),
  index('posts_post_type_idx').on(table.postType),
  index('posts_moderation_status_idx').on(table.moderationStatus),
]);

export const follows = pgTable('follows', {
  id: uuid('id').primaryKey().defaultRandom(),
  followerId: uuid('follower_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  followingId: uuid('following_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('follows_follower_id_idx').on(table.followerId),
  index('follows_following_id_idx').on(table.followingId),
  index('follows_follower_id_following_id_idx').on(table.followerId, table.followingId),
]);

export const notifications = pgTable('notifications', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  type: notificationTypeEnum('type').notNull(),
  title: text('title').notNull(),
  subtitle: text('subtitle'),
  relatedUserId: uuid('related_user_id').references(() => users.id, { onDelete: 'cascade' }),
  relatedPostId: uuid('related_post_id').references(() => posts.id, { onDelete: 'cascade' }),
  relatedQuizId: uuid('related_quiz_id').references(() => quizzes.id, { onDelete: 'cascade' }),
  isUnread: boolean('is_unread').notNull().default(true),
  status: text('status').notNull().default('PENDING'),
  deliveryChannel: text('delivery_channel'),
  retryCount: integer('retry_count').notNull().default(0),
  sentAt: timestamp('sent_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('notifications_user_id_idx').on(table.userId),
  index('notifications_is_unread_idx').on(table.isUnread),
  index('notifications_created_at_idx').on(table.createdAt),
  unique('notifications_unique_constraint').on(table.userId, table.type, table.relatedUserId, table.relatedPostId, table.relatedQuizId),
]);

export const userNotificationState = pgTable('user_notification_state', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('user_notification_state_user_id_idx').on(table.userId),
]);

export const systemLogs = pgTable('system_logs', {
  id: uuid('id').primaryKey().defaultRandom(),
  timestamp: timestamp('timestamp', { withTimezone: true }).defaultNow().notNull(),
  level: logLevelEnum('level').notNull(),
  message: text('message').notNull(),
  metadata: jsonb('metadata'),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  endpoint: varchar('endpoint', { length: 255 }),
  method: varchar('method', { length: 10 }),
  statusCode: integer('status_code'),
  duration: integer('duration'),
  error: text('error'),
  ipAddress: varchar('ip_address', { length: 45 }),
  userAgent: text('user_agent'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('system_logs_timestamp_idx').on(table.timestamp),
  index('system_logs_level_idx').on(table.level),
  index('system_logs_user_id_idx').on(table.userId),
  index('system_logs_endpoint_idx').on(table.endpoint),
  index('system_logs_created_at_idx').on(table.createdAt),
]);

// export const usersRelations = relations(users, ({ many }) => ({
//   quizzes: many(quizzes),
//   collections: many(collections),
//   hostedSessions: many(gameSessions),
//   favoriteQuizzes: many(favoriteQuizzes),
//   posts: many(posts),
//   followers: many(follows, { relationName: 'following' }),
//   following: many(follows, { relationName: 'follower' }),
//   notifications: many(notifications),
//   userQuestionTimings: many(userQuestionTimings),
// }));

// export const collectionsRelations = relations(collections, ({ one, many }) => ({
//   user: one(users, {
//     fields: [collections.userId],
//     references: [users.id],
//   }),
//   quizzes: many(quizzes),
// }));

// export const quizzesRelations = relations(quizzes, ({ one, many }) => ({
//    user: one(users, {
//      fields: [quizzes.userId],
//      references: [users.id],
//    }),
//    collection: one(collections, {
//      fields: [quizzes.collectionId],
//      references: [collections.id],
//    }),
//    questions: many(questions),
//    snapshots: many(quizSnapshots),
//  }));

// export const questionsRelations = relations(questions, ({ one, many }) => ({
//   quiz: one(quizzes, {
//     fields: [questions.quizId],
//     references: [quizzes.id],
//   }),
//   userQuestionTimings: many(userQuestionTimings),
// }));

export const quizSnapshotsRelations = relations(quizSnapshots, ({ one, many }) => ({
   quiz: one(quizzes, {
     fields: [quizSnapshots.quizId],
     references: [quizzes.id],
   }),
   questions: many(questionsSnapshots),
   gameSessions: many(gameSessions),
 }));

export const questionsSnapshotsRelations = relations(questionsSnapshots, ({ one, many }) => ({
  snapshot: one(quizSnapshots, {
    fields: [questionsSnapshots.snapshotId],
    references: [quizSnapshots.id],
  }),
  questionTimings: many(questionTimings),
}));

export const gameSessionsRelations = relations(gameSessions, ({ one, many }) => ({
  host: one(users, {
    fields: [gameSessions.hostId],
    references: [users.id],
  }),
  quizSnapshot: one(quizSnapshots, {
    fields: [gameSessions.quizSnapshotId],
    references: [quizSnapshots.id],
  }),
  participants: many(gameSessionParticipants),
  questionTimings: many(questionTimings),
}));

export const gameSessionParticipantsRelations = relations(gameSessionParticipants, ({ one, many }) => ({
  session: one(gameSessions, {
    fields: [gameSessionParticipants.sessionId],
    references: [gameSessions.id],
  }),
  user: one(users, {
    fields: [gameSessionParticipants.userId],
    references: [users.id],
  }),
  questionTimings: many(questionTimings),
}));

export const favoriteQuizzesRelations = relations(favoriteQuizzes, ({ one }) => ({
   user: one(users, {
     fields: [favoriteQuizzes.userId],
     references: [users.id],
   }),
   quiz: one(quizzes, {
     fields: [favoriteQuizzes.quizId],
     references: [quizzes.id],
   }),
 }));

export const postsRelations = relations(posts, ({ one, many }) => ({
   user: one(users, {
     fields: [posts.userId],
     references: [users.id],
   }),
   likes: many(postLikes),
   comments: many(comments),
 }));

// export const followsRelations = relations(follows, ({ one }) => ({
//   follower: one(users, {
//     fields: [follows.followerId],
//     references: [users.id],
//     relationName: 'follower',
//   }),
//   following: one(users, {
//     fields: [follows.followingId],
//     references: [users.id],
//     relationName: 'following',
//   }),
// }));

// export const notificationsRelations = relations(notifications, ({ one }) => ({
//    user: one(users, {
//      fields: [notifications.userId],
//      references: [users.id],
//    }),
//    relatedUser: one(users, {
//      fields: [notifications.relatedUserId],
//      references: [users.id],
//    }),
//    relatedPost: one(posts, {
//      fields: [notifications.relatedPostId],
//      references: [posts.id],
//    }),
//  }));

export const postLikesRelations = relations(postLikes, ({ one }) => ({
   user: one(users, {
     fields: [postLikes.userId],
     references: [users.id],
   }),
   post: one(posts, {
     fields: [postLikes.postId],
     references: [posts.id],
   }),
 }));

export const questionTimings = pgTable('question_timings', {
  id: uuid('id').primaryKey().defaultRandom(),
  participantId: uuid('participant_id').notNull().references(() => gameSessionParticipants.id, { onDelete: 'cascade' }),
  sessionId: uuid('session_id').notNull().references(() => gameSessions.id, { onDelete: 'cascade' }),
  questionSnapshotId: uuid('question_snapshot_id').notNull().references(() => questionsSnapshots.id, { onDelete: 'cascade' }),
  serverStartTime: timestamp('server_start_time', { withTimezone: true }).notNull(),
  deadlineTime: timestamp('deadline_time', { withTimezone: true }).notNull(),
  submittedAt: timestamp('submitted_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('question_timings_participant_session_idx').on(table.participantId, table.sessionId),
  index('question_timings_deadline_idx').on(table.deadlineTime),
  unique('question_timings_participant_question_unq').on(table.participantId, table.questionSnapshotId),
]);

export const questionTimingsRelations = relations(questionTimings, ({ one }) => ({
  participant: one(gameSessionParticipants, {
    fields: [questionTimings.participantId],
    references: [gameSessionParticipants.id],
  }),
  session: one(gameSessions, {
    fields: [questionTimings.sessionId],
    references: [gameSessions.id],
  }),
  questionSnapshot: one(questionsSnapshots, {
    fields: [questionTimings.questionSnapshotId],
    references: [questionsSnapshots.id],
  }),
}));

export const commentsRelations = relations(comments, ({ one, many }) => ({
   post: one(posts, {
     fields: [comments.postId],
     references: [posts.id],
   }),
   user: one(users, {
     fields: [comments.userId],
     references: [users.id],
   }),
   likes: many(commentLikes),
 }));

export const postReports = pgTable('post_reports', {
  id: uuid('id').primaryKey().defaultRandom(),
  postId: uuid('post_id').notNull().references(() => posts.id, { onDelete: 'cascade' }),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  reason: text('reason').notNull(),
  description: text('description'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('post_reports_post_id_idx').on(table.postId),
  index('post_reports_user_id_idx').on(table.userId),
  index('post_reports_created_at_idx').on(table.createdAt),
  unique('post_reports_user_post_unq').on(table.userId, table.postId),
]);

export const postReportsRelations = relations(postReports, ({ one }) => ({
  post: one(posts, {
    fields: [postReports.postId],
    references: [posts.id],
  }),
  user: one(users, {
    fields: [postReports.userId],
    references: [users.id],
  }),
}));

export const searchHistory = pgTable('search_history', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  query: text('query').notNull(),
  filterType: searchFilterTypeEnum('filter_type'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('search_history_user_id_idx').on(table.userId),
  index('search_history_created_at_idx').on(table.createdAt),
]);
