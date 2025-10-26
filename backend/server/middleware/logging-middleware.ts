import { MiddlewareHandler } from 'hono'
import { httpLogger, logger } from '../lib/logger'
import type { AuthContext } from './auth'

// Paths to exclude from HTTP logging (monitoring/admin read-only endpoints)
const EXCLUDED_PATHS = [
  '/api/admin/logs',      // Logs viewing endpoint (prevents recursive logging)
  '/admin/queues',        // BullMQ dashboard
  '/api/auth/check-admin', // Admin auth health check
]

/**
 * HTTP request/response logging middleware
 * Logs all API requests to database only (no console spam)
 */
export const loggingMiddleware: MiddlewareHandler = async (c, next) => {
  const startTime = Date.now()
  const method = c.req.method
  const path = c.req.path
  
  // Extract request details
  const ipAddress = c.req.header('x-forwarded-for') || c.req.header('x-real-ip') || 'unknown'
  const userAgent = c.req.header('user-agent') || 'unknown'
  
  // Get user context if authenticated (set by authMiddleware)
  let userId: string | undefined
  try {
    const user = c.get('user') as AuthContext | undefined
    userId = user?.userId
  } catch {
    // User not authenticated, that's fine
  }
  
  // Execute the request
  await next()
  
  // Skip logging for excluded paths (only for successful GET requests)
  // Still log errors and mutations (POST/PUT/DELETE)
  const isExcluded = EXCLUDED_PATHS.some(excludedPath => path.startsWith(excludedPath))
  const isGetRequest = method === 'GET'
  const isSuccess = c.res.status < 400
  
  if (isExcluded && isGetRequest && isSuccess) {
    return // Skip logging for monitoring endpoints
  }
  
  // Calculate duration
  const duration = Date.now() - startTime
  const statusCode = c.res.status
  
  // Determine log level based on status code
  const level = statusCode >= 500 ? 'error' : statusCode >= 400 ? 'warn' : 'info'
  
  // Build log message
  const message = `${method} ${path} ${statusCode} - ${duration}ms`
  
  // Log with structured data (using httpLogger - database only, no console)
  const logData = {
    userId,
    endpoint: path,
    method,
    statusCode,
    duration,
    ipAddress,
    userAgent,
  }
  
  if (level === 'error') {
    httpLogger.error(logData, message)
  } else if (level === 'warn') {
    httpLogger.warn(logData, message)
  } else {
    httpLogger.info(logData, message)
  }
}

/**
 * Error logging middleware
 * Catches and logs unhandled errors in routes
 */
export const errorLoggingMiddleware: MiddlewareHandler = async (c, next) => {
  try {
    await next()
  } catch (error) {
    const err = error as Error
    
    // Get user context if available
    let userId: string | undefined
    try {
      const user = c.get('user') as AuthContext | undefined
      userId = user?.userId
    } catch {
      // User not authenticated
    }
    
    // Log the error (use regular logger for errors - we want to see these in console)
    logger.error({
      userId,
      endpoint: c.req.path,
      method: c.req.method,
      error: err.message,
      metadata: {
        stack: err.stack,
        name: err.name,
      }
    }, `Unhandled error: ${err.message}`)
    
    // Re-throw to let Hono's error handler deal with it
    throw error
  }
}
