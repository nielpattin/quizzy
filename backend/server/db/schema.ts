import { pgTable, text, timestamp, uuid, boolean, varchar, date } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: uuid('id').primaryKey(),
  email: text('email').notNull().unique(),
  fullName: text('full_name').notNull().default(''),
  username: varchar('username', { length: 50 }).unique(),
  dob: date('dob'),
  bio: text('bio'),
  profilePictureUrl: text('profile_picture_url'),
  accountType: text('account_type').notNull().default('student'),
  isSetupComplete: boolean('is_setup_complete').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});
