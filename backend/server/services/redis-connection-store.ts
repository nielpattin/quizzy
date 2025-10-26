import Redis from 'ioredis'

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || undefined,
})

interface ConnectionMetadata {
  userId: string
  email: string
  connectedAt: number
  lastPing: number
}

const CONNECTION_TTL = 90 // seconds - 3x the ping interval
const KEY_PREFIX = 'ws:user:'

/**
 * Redis-based WebSocket connection store
 * Persists connection state across server hot reloads
 */
export class RedisConnectionStore {
  /**
   * Add a user connection to Redis
   */
  static async addConnection(userId: string, email: string): Promise<void> {
    try {
      const metadata: ConnectionMetadata = {
        userId,
        email,
        connectedAt: Date.now(),
        lastPing: Date.now(),
      }
      
      await redis.setex(
        `${KEY_PREFIX}${userId}`,
        CONNECTION_TTL,
        JSON.stringify(metadata)
      )
      
      const shortUserId = userId.substring(0, 8)
      console.log(`[Redis] Added connection | user:${shortUserId} | ttl:${CONNECTION_TTL}s`)
    } catch (error) {
      console.error('[Redis] Error adding connection:', error)
    }
  }

  /**
   * Remove a user connection from Redis
   */
  static async removeConnection(userId: string): Promise<void> {
    try {
      await redis.del(`${KEY_PREFIX}${userId}`)
      const shortUserId = userId.substring(0, 8)
      console.log(`[Redis] Removed connection | user:${shortUserId}`)
    } catch (error) {
      console.error('[Redis] Error removing connection:', error)
    }
  }

  /**
   * Update heartbeat timestamp for a user (called on ping/pong)
   */
  static async updateHeartbeat(userId: string): Promise<void> {
    try {
      const key = `${KEY_PREFIX}${userId}`
      const data = await redis.get(key)
      
      if (data) {
        const metadata: ConnectionMetadata = JSON.parse(data)
        metadata.lastPing = Date.now()
        
        // Extend TTL
        await redis.setex(key, CONNECTION_TTL, JSON.stringify(metadata))
      }
    } catch (error) {
      console.error('[Redis] Error updating heartbeat:', error)
    }
  }

  /**
   * Check if a user is online (has active connection in Redis)
   */
  static async isUserOnline(userId: string): Promise<boolean> {
    try {
      const exists = await redis.exists(`${KEY_PREFIX}${userId}`)
      return exists === 1
    } catch (error) {
      console.error('[Redis] Error checking user online:', error)
      return false
    }
  }

  /**
   * Get connection metadata for a user
   */
  static async getConnection(userId: string): Promise<ConnectionMetadata | null> {
    try {
      const data = await redis.get(`${KEY_PREFIX}${userId}`)
      return data ? JSON.parse(data) : null
    } catch (error) {
      console.error('[Redis] Error getting connection:', error)
      return null
    }
  }

  /**
   * Get all online user IDs
   */
  static async getOnlineUsers(): Promise<string[]> {
    try {
      const keys = await redis.keys(`${KEY_PREFIX}*`)
      return keys.map(key => key.replace(KEY_PREFIX, ''))
    } catch (error) {
      console.error('[Redis] Error getting online users:', error)
      return []
    }
  }

  /**
   * Get count of online users
   */
  static async getOnlineCount(): Promise<number> {
    try {
      const keys = await redis.keys(`${KEY_PREFIX}*`)
      return keys.length
    } catch (error) {
      console.error('[Redis] Error getting online count:', error)
      return 0
    }
  }

  /**
   * Clean up connections older than TTL (should be handled by Redis TTL automatically)
   */
  static async cleanup(): Promise<number> {
    try {
      const keys = await redis.keys(`${KEY_PREFIX}*`)
      let cleaned = 0
      
      for (const key of keys) {
        const data = await redis.get(key)
        if (data) {
          const metadata: ConnectionMetadata = JSON.parse(data)
          const age = Date.now() - metadata.lastPing
          
          // Remove if no ping for more than TTL
          if (age > CONNECTION_TTL * 1000) {
            await redis.del(key)
            cleaned++
          }
        }
      }
      
      if (cleaned > 0) {
        console.log(`[Redis] Cleaned up ${cleaned} stale connection(s)`)
      }
      
      return cleaned
    } catch (error) {
      console.error('[Redis] Error during cleanup:', error)
      return 0
    }
  }
}
