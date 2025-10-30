import { db } from './db/index'
import { gameSessions, gameSessionParticipants, users, questionTimings } from './db/schema'
import { eq, and, desc } from 'drizzle-orm'
import { supabase } from './lib/supabase'
import { RedisConnectionStore } from './services/redis-connection-store'
import { WebSocketService } from './services/websocket-service'

// WebSocket connection context type
export interface WebSocketContext {
  userId: string
  email: string
  sessionId?: string
  userMetadata?: {
    full_name?: string
    avatar_url?: string
    name?: string
    picture?: string
  }
}

// WebSocket message types (simplified for Mode 1 + social features)
export type WebSocketMessage = 
  | { type: 'join_session'; sessionId: string }
  | { type: 'leave_session'; sessionId: string }
  | { type: 'session_update'; sessionId: string; data: any }
  | { type: 'session_state'; sessionId: string; data: any }
  | { type: 'session_started'; sessionId: string }
  | { type: 'participant_joined'; sessionId: string; participant: any }
  | { type: 'participant_left'; sessionId: string; participantId: string }
  | { type: 'error'; message: string }
  | { type: 'ping' }
  | { type: 'pong' }
  | { type: 'new_follower'; data: any }
  | { type: 'quiz_shared'; data: any }
  | { type: 'new_comment'; data: any }

// Active connections store
export const activeConnections = new Map<any, WebSocketContext>()
const sessionParticipants = new Map<string, Set<any>>()

// Helper function to broadcast to session participants
export function broadcastToSession(sessionId: string, message: WebSocketMessage, exclude?: any) {
  const participants = sessionParticipants.get(sessionId)
  if (!participants) return

  const messageStr = JSON.stringify(message)
  
  participants.forEach((ws) => {
    if (ws !== exclude && ws.readyState === 1) { // 1 = WebSocket.OPEN
      try {
        ws.send(messageStr)
      } catch (error) {
        console.error('Error sending message to WebSocket:', error)
      }
    }
  })
}

// Helper function to send message to specific connection
export function sendToConnection(ws: any, message: WebSocketMessage) {
  if (ws.readyState === 1) { // 1 = WebSocket.OPEN
    try {
      ws.send(JSON.stringify(message))
    } catch (error) {
      console.error('Error sending message to WebSocket:', error)
    }
  }
}

// Helper function to get session participants count
export function getSessionParticipantCount(sessionId: string): number {
  const participants = sessionParticipants.get(sessionId)
  return participants ? participants.size : 0
}

// Helper function to get user info from WebSocket context
export async function getUserInfo(userId: string) {
  try {
    const [user] = await db
      .select({
        id: users.id,
        username: users.username,
        fullName: users.fullName,
        profilePictureUrl: users.profilePictureUrl,
      })
      .from(users)
      .where(eq(users.id, userId))

    return user
  } catch (error) {
    console.error('Error fetching user info:', error)
    return null
  }
}

// Helper function to validate session exists
export async function validateSession(sessionId: string) {
  try {
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    return session
  } catch (error) {
    console.error('Error validating session:', error)
    return null
  }
}

// Helper function to add participant to session
export function addParticipantToSession(sessionId: string, ws: any) {
  if (!sessionParticipants.has(sessionId)) {
    sessionParticipants.set(sessionId, new Set())
  }
  sessionParticipants.get(sessionId)!.add(ws)
}

// Helper function to remove participant from session
export function removeParticipantFromSession(sessionId: string, ws: any) {
  const participants = sessionParticipants.get(sessionId)
  if (participants) {
    participants.delete(ws)
    if (participants.size === 0) {
      sessionParticipants.delete(sessionId)
    }
  }
}

// Helper function to remove connection from all sessions
export function removeConnectionFromAllSessions(ws: any) {
  const context = activeConnections.get(ws)
  if (context && context.sessionId) {
    removeParticipantFromSession(context.sessionId, ws)
  }
  activeConnections.delete(ws)
}

// Authentication during WebSocket upgrade
export async function authenticateWebSocket(request: Request): Promise<WebSocketContext | null> {
  try {
    // Try to get token from query parameter first
    const url = new URL(request.url)
    let token = url.searchParams.get('token')
    
    // Fall back to Authorization header
    if (!token) {
      const authHeader = request.headers.get('Authorization')
      if (authHeader && authHeader.startsWith('Bearer ')) {
        token = authHeader.replace('Bearer ', '')
      }
    }
    
    if (!token) {
      return null
    }

    // Verify token with Supabase
    const { data, error } = await supabase.auth.getUser(token)

    if (error || !data.user) {
      return null
    }

    return {
      userId: data.user.id,
      email: data.user.email!,
      userMetadata: data.user.user_metadata,
    }
  } catch (error) {
    console.error('WebSocket authentication error:', error)
    return null
  }
}

// Handle WebSocket messages
export async function handleWebSocketMessage(ws: any, message: string, context: WebSocketContext) {
  try {
    const data = JSON.parse(message) as WebSocketMessage

    switch (data.type) {
      case 'join_session':
        await handleJoinSession(ws, data.sessionId, context)
        break

      case 'leave_session':
        await handleLeaveSession(ws, data.sessionId, context)
        break

      case 'ping':
        // Update Redis heartbeat to keep connection alive
        await RedisConnectionStore.updateHeartbeat(context.userId)
        sendToConnection(ws, { type: 'pong' })
        break

      case 'pong':
        // Client pong received, connection is alive
        await RedisConnectionStore.updateHeartbeat(context.userId)
        break

      default:
        sendToConnection(ws, { type: 'error', message: 'Unknown message type' })
    }
  } catch (error) {
    console.error('Error handling WebSocket message:', error)
    sendToConnection(ws, { type: 'error', message: 'Invalid message format' })
  }
}

// Handle session join
async function handleJoinSession(ws: any, sessionId: string, context: WebSocketContext) {
  try {
    console.log(`[WebSocket] Received join_session for session ${sessionId} from user ${context.userId}`)
    
    // Validate session exists
    const session = await validateSession(sessionId)
    if (!session) {
      console.log(`[WebSocket] Session not found: ${sessionId}`)
      sendToConnection(ws, { type: 'error', message: 'Session not found' })
      return
    }

    // Check if session has ended
    if (session.endedAt) {
      // Allow existing participants to rejoin for "Play Again"
      const existingParticipants = await db
        .select()
        .from(gameSessionParticipants)
        .where(and(
          eq(gameSessionParticipants.sessionId, sessionId),
          eq(gameSessionParticipants.userId, context.userId)
        ))
      
      // If no previous participation, reject
      if (existingParticipants.length === 0) {
        console.log(`[WebSocket] Session has ended and user has no previous participation: ${sessionId}`)
        sendToConnection(ws, { type: 'error', message: 'Session has ended' })
        return
      }
      
      console.log(`[WebSocket] Session has ended but allowing existing participant to rejoin for Play Again: ${sessionId}`)
      // Continue to allow rejoin for Play Again
    }

    // Remove from previous session if switching to a different session
    // Don't leave if re-joining the same session (prevents deleting participant record)
    if (context.sessionId && context.sessionId !== sessionId) {
      await handleLeaveSession(ws, context.sessionId, context)
    }

    // Update context with new session
    context.sessionId = sessionId
    activeConnections.set(ws, context)

    // Add to session participants
    addParticipantToSession(sessionId, ws)

    // Get user info
    const userInfo = await getUserInfo(context.userId)
    if (!userInfo) {
      console.log(`[WebSocket] User not found: ${context.userId}`)
      sendToConnection(ws, { type: 'error', message: 'User not found' })
      return
    }

    // Get participant record from database (if exists)
    const [participantRecord] = await db
      .select()
      .from(gameSessionParticipants)
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, context.userId)
      ))
      .limit(1)

    // Broadcast if user is a participant
    // Note: HTTP endpoint also broadcasts, but frontend deduplicates by userId
    // This ensures joiners who connect after HTTP broadcast still see themselves
    if (participantRecord) {
      console.log(`[WebSocket] User ${context.userId} is a participant - broadcasting`)
      
      // Broadcast complete participant data to ALL participants
      const participantData = {
        id: participantRecord.id,
        userId: context.userId,
        username: userInfo.username,
        fullName: userInfo.fullName,
        profilePictureUrl: userInfo.profilePictureUrl,
        score: participantRecord.score,
        rank: participantRecord.rank,
        joinedAt: participantRecord.joinedAt.toISOString(),
      }

      broadcastToSession(sessionId, {
        type: 'participant_joined',
        sessionId,
        participant: participantData,
      })

      console.log(`[WebSocket] Broadcasted participant_joined for user ${context.userId}`)
    } else {
      console.log(`[WebSocket] User ${context.userId} joined WebSocket as observer (not a participant)`)
    }

    // Fetch unique participants (latest attempt per user) for this session
    // Get all participants first, then deduplicate in memory to get latest per userId
    const allParticipantRecords = await db
      .select({
        id: gameSessionParticipants.id,
        userId: gameSessionParticipants.userId,
        score: gameSessionParticipants.score,
        rank: gameSessionParticipants.rank,
        joinedAt: gameSessionParticipants.joinedAt,
        username: users.username,
        fullName: users.fullName,
        profilePictureUrl: users.profilePictureUrl,
      })
      .from(gameSessionParticipants)
      .innerJoin(users, eq(gameSessionParticipants.userId, users.id))
      .where(eq(gameSessionParticipants.sessionId, sessionId))
      .orderBy(desc(gameSessionParticipants.joinedAt))

    // Deduplicate: keep only latest participant per userId
    const uniqueParticipants = new Map()
    for (const participant of allParticipantRecords) {
      if (!uniqueParticipants.has(participant.userId)) {
        uniqueParticipants.set(participant.userId, participant)
      }
    }
    const allParticipants = Array.from(uniqueParticipants.values())

    // Send session state with full participant list to joining user
    sendToConnection(ws, {
      type: 'session_state',
      sessionId,
      data: {
        id: session.id,
        title: session.title,
        isLive: session.isLive,
        participantCount: session.participantCount, // Database value (completed plays)
        playerCount: session.playerCount, // Unique users who joined
        participants: allParticipants.map(p => ({
          id: p.id,
          userId: p.userId,
          username: p.username,
          fullName: p.fullName,
          profilePictureUrl: p.profilePictureUrl,
          score: p.score,
          rank: p.rank,
          joinedAt: p.joinedAt.toISOString(),
        })),
      },
    })

    console.log(`[WebSocket] User ${context.userId} successfully joined session ${sessionId} with ${allParticipants.length} participants`)
  } catch (error) {
    console.error('[WebSocket] Error handling session join:', error)
    sendToConnection(ws, { type: 'error', message: 'Failed to join session' })
  }
}

// Handle session leave
async function handleLeaveSession(ws: any, sessionId: string, context: WebSocketContext) {
  try {
    // Remove participant from database (same logic as HTTP leave endpoint)
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (session) {
      // Find the LATEST participant for this user in this session
      const [existingParticipant] = await db
        .select()
        .from(gameSessionParticipants)
        .where(and(
          eq(gameSessionParticipants.sessionId, sessionId),
          eq(gameSessionParticipants.userId, context.userId)
        ))
        .orderBy(desc(gameSessionParticipants.joinedAt))
        .limit(1)

      if (existingParticipant) {
        // Check if participant has started playing (has any question_timings)
        const timings = await db
          .select()
          .from(questionTimings)
          .where(eq(questionTimings.participantId, existingParticipant.id))
          .limit(1)

        // Only delete participant if they haven't started playing
        // If they have timings, preserve their game progress
        if (timings.length === 0) {
          // No timings = lobby member only, safe to delete
          // Delete by ID to avoid deleting all participants for this user
          await db
            .delete(gameSessionParticipants)
            .where(eq(gameSessionParticipants.id, existingParticipant.id))

          // Update session joined count
          await db
            .update(gameSessions)
            .set({
              participantCount: Math.max(0, session.participantCount - 1),
            })
            .where(eq(gameSessions.id, sessionId))

          console.log(`[WebSocket] Deleted lobby participant ${context.userId} from session ${sessionId}`)
        } else {
          console.log(`[WebSocket] Preserved participant ${context.userId} with game progress in session ${sessionId}`)
        }

        // Broadcast participant left event
        await WebSocketService.broadcastParticipantLeft(sessionId, context.userId)
      }
    }

    // Remove from WebSocket session participants
    removeParticipantFromSession(sessionId, ws)

    // Clear session from context
    context.sessionId = undefined
    activeConnections.set(ws, context)

    console.log(`User ${context.userId} left session ${sessionId}`)
  } catch (error) {
    console.error('Error handling session leave:', error)
  }
}

// Handle WebSocket connection close
export async function handleWebSocketClose(ws: any) {
  try {
    const context = activeConnections.get(ws)
    if (context) {
      const shortUserId = context.userId.substring(0, 8)
      
      // Unsubscribe from Redis notification channel
      await RedisConnectionStore.unsubscribeFromUser(context.userId)
      
      // Remove from Redis
      await RedisConnectionStore.removeConnection(context.userId)
      
      // Remove from all sessions
      removeConnectionFromAllSessions(ws)

      // Broadcast leave message if was in a session
      if (context.sessionId) {
        broadcastToSession(context.sessionId, {
          type: 'participant_left',
          sessionId: context.sessionId,
          participantId: context.userId,
        }, ws)
      }

      const totalConnections = activeConnections.size
      console.log(`[WS] Connection closed | user:${shortUserId} | email:${context.email} | remaining:${totalConnections}`)
    }
  } catch (error) {
    console.error('[WS] Error handling close:', error)
  }
}

// Handle WebSocket errors
export function handleWebSocketError(ws: any, error: any) {
  const context = activeConnections.get(ws)
  const shortUserId = context?.userId?.substring(0, 8) || 'unknown'
  console.error(`[WS] Connection error | user:${shortUserId} |`, error.message || error)
  removeConnectionFromAllSessions(ws)
}

// Get active connections count
export function getActiveConnectionsCount(): number {
  return activeConnections.size
}

// Get session participants info
export function getSessionParticipants(sessionId: string): WebSocketContext[] {
  const participants = sessionParticipants.get(sessionId)
  if (!participants) return []

  return Array.from(participants)
    .map(ws => activeConnections.get(ws))
    .filter(Boolean) as WebSocketContext[]
}

// Check if user is online (check Redis for persistence across hot reloads)
export async function isUserOnline(userId: string): Promise<boolean> {
  // Check Redis first (persists across hot reloads)
  const inRedis = await RedisConnectionStore.isUserOnline(userId)
  if (inRedis) return true
  
  // Fallback to local Map (faster for recently connected users)
  for (const context of activeConnections.values()) {
    if (context.userId === userId) {
      return true
    }
  }
  return false
}

// Get real-time session info including active WebSocket connections
export async function getSessionRealtimeInfo(sessionId: string) {
  try {
    const [session] = await db
      .select({
        id: gameSessions.id,
        title: gameSessions.title,
        isLive: gameSessions.isLive,
        participantCount: gameSessions.participantCount,
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

// Cleanup function for server shutdown
export async function cleanupWebSocketConnections() {
  console.log('[WS] Cleaning up WebSocket connections...')
  
  // Close all active connections
  activeConnections.forEach((context, ws) => {
    try {
      ws.close(1000, 'Server shutting down')
    } catch (error) {
      console.error('Error closing WebSocket:', error)
    }
  })

  // Clear all stores
  activeConnections.clear()
  sessionParticipants.clear()

  // Note: We DON'T clear Redis here - let TTL handle it
  // This allows us to know users were recently connected after hot reload
  
  console.log('[WS] WebSocket connections cleaned up')
}