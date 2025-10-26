import { db } from '../db/index'
import { gameSessions, gameSessionParticipants, users, quizzes } from '../db/schema'
import { eq, and, desc } from 'drizzle-orm'
import {
  broadcastToSession,
  getSessionParticipants,
  getUserInfo,
  isUserOnline,
  WebSocketMessage,
  activeConnections,
} from '../websocket'
import { RedisConnectionStore } from './redis-connection-store'

// Simplified WebSocket service for essential real-time features only
export class WebSocketService {
  // Broadcast participant joined event (called from HTTP join endpoint)
  static async broadcastParticipantJoined(sessionId: string, userId: string) {
    try {
      const userInfo = await getUserInfo(userId)
      if (!userInfo) {
        console.error('User not found for participant broadcast:', userId)
        return
      }

      const message: WebSocketMessage = {
        type: 'participant_joined',
        sessionId,
        participant: {
          id: userId,
          username: userInfo.username,
          fullName: userInfo.fullName,
          profilePictureUrl: userInfo.profilePictureUrl,
        },
      }

      broadcastToSession(sessionId, message)
      console.log(`Broadcasted participant joined for user ${userId} in session ${sessionId}`)
    } catch (error) {
      console.error('Error broadcasting participant joined:', error)
    }
  }

  // Broadcast participant left event (called from HTTP leave endpoint)
  static async broadcastParticipantLeft(sessionId: string, userId: string) {
    try {
      const message: WebSocketMessage = {
        type: 'participant_left',
        sessionId,
        participantId: userId,
      }

      broadcastToSession(sessionId, message)
      console.log(`Broadcasted participant left for user ${userId} in session ${sessionId}`)
    } catch (error) {
      console.error('Error broadcasting participant left:', error)
    }
  }

  // Broadcast new follower event (social notification)
  static async broadcastNewFollower(followedUserId: string, followerId: string) {
    try {
      const followerInfo = await getUserInfo(followerId)
      if (!followerInfo) {
        console.error('Follower not found for broadcast:', followerId)
        return
      }

      const message: WebSocketMessage = {
        type: 'new_follower' as any,
        data: {
          follower: {
            id: followerInfo.id,
            username: followerInfo.username,
            fullName: followerInfo.fullName,
            profilePictureUrl: followerInfo.profilePictureUrl,
          },
        },
      }

      broadcastToSession(`user_${followedUserId}`, message)
      console.log(`Broadcasted new follower notification to user ${followedUserId}`)
    } catch (error) {
      console.error('Error broadcasting new follower:', error)
    }
  }

  // Broadcast to specific user
  static async broadcastToUser(userId: string, message: any): Promise<boolean> {
    try {
      const shortUserId = userId.substring(0, 8)
      
      // Use Redis pub/sub as single source of truth for delivery
      // This is hot-reload proof - if user is subscribed, they'll receive it
      const delivered = await RedisConnectionStore.publishNotification(userId, message)
      
      if (delivered) {
        console.log(`[WS] Published to Redis -> user:${shortUserId} | type:${message.type} | via:pubsub`)
      } else {
        console.log(`[WS] User offline -> user:${shortUserId} | no subscribers`)
      }
      
      return delivered
    } catch (error) {
      console.error('[WS] Error broadcasting to user:', error)
      return false
    }
  }

  // Check if user is online
  static async isUserOnline(userId: string): Promise<boolean> {
    // Check Redis first (persists across hot reloads)
    return await isUserOnline(userId)
  }

  // Broadcast quiz shared event (social notification)
  static async broadcastQuizShared(quizId: string, sharedByUserId: string) {
    try {
      const [quiz] = await db
        .select({
          id: quizzes.id,
          title: quizzes.title,
          userId: quizzes.userId,
        })
        .from(quizzes)
        .where(eq(quizzes.id, quizId))

      if (!quiz) {
        console.error('Quiz not found for share broadcast:', quizId)
        return
      }

      const sharedByInfo = await getUserInfo(sharedByUserId)
      if (!sharedByInfo) {
        console.error('Sharing user not found for broadcast:', sharedByUserId)
        return
      }

      const message: WebSocketMessage = {
        type: 'quiz_shared' as any,
        data: {
          quiz: {
            id: quiz.id,
            title: quiz.title,
          },
          sharedBy: {
            id: sharedByInfo.id,
            username: sharedByInfo.username,
            fullName: sharedByInfo.fullName,
            profilePictureUrl: sharedByInfo.profilePictureUrl,
          },
        },
      }

      // Broadcast to general "social" topic for feed updates
      broadcastToSession('social', message)
      console.log(`Broadcasted quiz shared event for quiz ${quizId}`)
    } catch (error) {
      console.error('Error broadcasting quiz shared:', error)
    }
  }

  // Broadcast new comment event (social notification)
  static async broadcastNewComment(postId: string, commentUserId: string) {
    try {
      const commentUserInfo = await getUserInfo(commentUserId)
      if (!commentUserInfo) {
        console.error('Comment user not found for broadcast:', commentUserId)
        return
      }

      const message: WebSocketMessage = {
        type: 'new_comment' as any,
        data: {
          postId,
          user: {
            id: commentUserInfo.id,
            username: commentUserInfo.username,
            fullName: commentUserInfo.fullName,
            profilePictureUrl: commentUserInfo.profilePictureUrl,
          },
        },
      }

      // Broadcast to post participants
      broadcastToSession(`post_${postId}`, message)
      console.log(`Broadcasted new comment event for post ${postId}`)
    } catch (error) {
      console.error('Error broadcasting new comment:', error)
    }
  }

  // Get real-time session info including active WebSocket connections
  static async getSessionRealtimeInfo(sessionId: string) {
    try {
      const [session] = await db
        .select({
          id: gameSessions.id,
          title: gameSessions.title,
          isLive: gameSessions.isLive,
          joinedCount: gameSessions.joinedCount,
          startedAt: gameSessions.startedAt,
          endedAt: gameSessions.endedAt,
        })
        .from(gameSessions)
        .where(eq(gameSessions.id, sessionId))

      if (!session) {
        return null
      }

      const websocketParticipants = getSessionParticipants(sessionId)
      const activeConnections = websocketParticipants.length

      return {
        ...session,
        activeConnections,
        websocketParticipants: websocketParticipants.map(p => ({
          userId: p.userId,
          email: p.email,
          username: p.userMetadata?.full_name || p.email,
        })),
      }
    } catch (error) {
      console.error('Error getting session realtime info:', error)
      return null
    }
  }

  // Get statistics about WebSocket connections
  static getWebSocketStats() {
    try {
      const stats = {
        totalConnections: 0,
        activeSessions: 0,
        sessionDetails: {} as Record<string, number>,
      }

      // This would need to be implemented by exposing the internal maps
      // For now, we'll return basic stats
      return {
        ...stats,
        message: 'WebSocket stats tracking to be implemented',
      }
    } catch (error) {
      console.error('Error getting WebSocket stats:', error)
      return null
    }
  }
}