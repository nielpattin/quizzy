import { db } from '../db/index'
import { notifications, users, posts, quizzes } from '../db/schema'
import { eq } from 'drizzle-orm'
import { enqueueNotification } from './notification-queue'

export type NotificationType = 'like' | 'comment' | 'follow' | 'quiz_share' | 'game_invite' | 'mention' | 'quiz_answer' | 'follow_request' | 'system'

export interface CreateNotificationData {
  userId: string
  type: NotificationType
  title: string
  subtitle?: string
  relatedUserId?: string
  relatedPostId?: string
  relatedQuizId?: string
}

export class NotificationService {
  // Create a notification
  static async createNotification(data: CreateNotificationData) {
    try {
      const [notification] = await db
        .insert(notifications)
        .values({
          userId: data.userId,
          type: data.type,
          title: data.title,
          subtitle: data.subtitle,
          relatedUserId: data.relatedUserId,
          relatedPostId: data.relatedPostId,
          relatedQuizId: data.relatedQuizId,
        })
        .returning()

      const shortUserId = data.userId.substring(0, 8)
      console.log(`[API] New notification -> user:${shortUserId} | type:${data.type} | "${data.title}"`)

      await enqueueNotification({
        notificationId: notification.id,
        userId: data.userId,
        type: data.type,
      })

      return notification
    } catch (error) {
      console.error('Error creating notification:', error)
      throw error
    }
  }

  // Create notification when someone likes a post
  static async createPostLikeNotification(likerId: string, postId: string) {
    try {
      // Get post owner
      const [post] = await db
        .select({ userId: posts.userId })
        .from(posts)
        .where(eq(posts.id, postId))

      if (!post || post.userId === likerId) {
        return // Don't notify if liking own post
      }

      // Get liker info
      const [liker] = await db
        .select({ fullName: users.fullName, username: users.username })
        .from(users)
        .where(eq(users.id, likerId))

      if (!liker) return

      const displayName = liker.username || liker.fullName

      await this.createNotification({
        userId: post.userId,
        type: 'like',
        title: 'New Like',
        subtitle: `${displayName} liked your post`,
        relatedUserId: likerId,
        relatedPostId: postId,
      })
    } catch (error) {
      console.error('Error creating post like notification:', error)
    }
  }

  // Create notification when someone comments on a post
  static async createCommentNotification(commenterId: string, postId: string) {
    try {
      // Get post owner
      const [post] = await db
        .select({ userId: posts.userId })
        .from(posts)
        .where(eq(posts.id, postId))

      if (!post || post.userId === commenterId) {
        return // Don't notify if commenting on own post
      }

      // Get commenter info
      const [commenter] = await db
        .select({ fullName: users.fullName, username: users.username })
        .from(users)
        .where(eq(users.id, commenterId))

      if (!commenter) return

      const displayName = commenter.username || commenter.fullName

      await this.createNotification({
        userId: post.userId,
        type: 'comment',
        title: 'New Comment',
        subtitle: `${displayName} commented on your post`,
        relatedUserId: commenterId,
        relatedPostId: postId,
      })
    } catch (error) {
      console.error('Error creating comment notification:', error)
    }
  }

  // Create notification when someone follows a user
  static async createFollowNotification(followerId: string, followedUserId: string) {
    try {
      // Get follower info
      const [follower] = await db
        .select({ fullName: users.fullName, username: users.username })
        .from(users)
        .where(eq(users.id, followerId))

      if (!follower) return

      const displayName = follower.username || follower.fullName

      await this.createNotification({
        userId: followedUserId,
        type: 'follow',
        title: 'New Follower',
        subtitle: `${displayName} started following you`,
        relatedUserId: followerId,
      })
    } catch (error) {
      console.error('Error creating follow notification:', error)
    }
  }

  // Create notification when someone shares a quiz
  static async createQuizShareNotification(sharerId: string, quizId: string) {
    try {
      // Get quiz owner
      const [quiz] = await db
        .select({ userId: quizzes.userId, title: quizzes.title })
        .from(quizzes)
        .where(eq(quizzes.id, quizId))

      if (!quiz || quiz.userId === sharerId) {
        return // Don't notify if sharing own quiz
      }

      // Get sharer info
      const [sharer] = await db
        .select({ fullName: users.fullName, username: users.username })
        .from(users)
        .where(eq(users.id, sharerId))

      if (!sharer) return

      const displayName = sharer.username || sharer.fullName

      await this.createNotification({
        userId: quiz.userId,
        type: 'quiz_share',
        title: 'Quiz Shared',
        subtitle: `${displayName} shared your quiz "${quiz.title}"`,
        relatedUserId: sharerId,
        relatedQuizId: quizId,
      })
    } catch (error) {
      console.error('Error creating quiz share notification:', error)
    }
  }

  // Create notification for quiz invitation
  static async createGameInviteNotification(hostId: string, inviteeId: string, quizId: string) {
    try {
      // Get host and quiz info
      const [host] = await db
        .select({ fullName: users.fullName, username: users.username })
        .from(users)
        .where(eq(users.id, hostId))

      const [quiz] = await db
        .select({ title: quizzes.title })
        .from(quizzes)
        .where(eq(quizzes.id, quizId))

      if (!host || !quiz) return

      const displayName = host.username || host.fullName

      await this.createNotification({
        userId: inviteeId,
        type: 'game_invite',
        title: 'Game Invitation',
        subtitle: `${displayName} invited you to play "${quiz.title}"`,
        relatedUserId: hostId,
        relatedQuizId: quizId,
      })
    } catch (error) {
      console.error('Error creating game invite notification:', error)
    }
  }

  // Create notification when someone answers a quiz post
  static async createQuizAnswerNotification(answererId: string, postId: string) {
    try {
      // Get post owner
      const [post] = await db
        .select({ userId: posts.userId })
        .from(posts)
        .where(eq(posts.id, postId))

      if (!post || post.userId === answererId) {
        return // Don't notify if answering own quiz
      }

      // Get answerer info
      const [answerer] = await db
        .select({ fullName: users.fullName, username: users.username })
        .from(users)
        .where(eq(users.id, answererId))

      if (!answerer) return

      const displayName = answerer.username || answerer.fullName

      await this.createNotification({
        userId: post.userId,
        type: 'quiz_answer',
        title: 'Quiz Answered',
        subtitle: `${displayName} answered your quiz`,
        relatedUserId: answererId,
        relatedPostId: postId,
      })
    } catch (error) {
      console.error('Error creating quiz answer notification:', error)
    }
  }
}