import pino from 'pino'
import pretty from 'pino-pretty'
import { db } from '../db/index'
import { systemLogs } from '../db/schema'

// Create a custom stream that writes to PostgreSQL
const postgresStream = {
  write: async (log: string) => {
    try {
      const logData = JSON.parse(log)
      
      // Only persist logs at info level and above (skip debug and trace in production)
      if (logData.level < 30) return // 30 = info, 40 = warn, 50 = error
      
      await db.insert(systemLogs).values({
        timestamp: new Date(logData.time),
        level: logData.level === 50 ? 'error' : logData.level === 40 ? 'warn' : 'info',
        message: logData.msg || '',
        metadata: logData.metadata || null,
        userId: logData.userId || null,
        endpoint: logData.endpoint || null,
        method: logData.method || null,
        statusCode: logData.statusCode || null,
        duration: logData.duration || null,
        error: logData.error || null,
        ipAddress: logData.ipAddress || null,
        userAgent: logData.userAgent || null,
      })
    } catch (error) {
      // Fallback to console if database write fails
      console.error('[Logger] Failed to write log to database:', error)
    }
  }
}

// Determine if we're in development
const isDevelopment = process.env.NODE_ENV !== 'production'

// Create pretty stream for console (development) or raw JSON (production)
const consoleStream = isDevelopment
  ? pretty({
      colorize: true,
      translateTime: 'HH:MM:ss.l',
      ignore: 'pid,hostname',
      messageFormat: '{msg}',
      customPrettifiers: {
        // Add custom formatting for specific fields
        endpoint: (endpoint: string) => `\n    endpoint: ${endpoint}`,
        method: (method: string) => `method: ${method}`,
        statusCode: (statusCode: number) => `status: ${statusCode}`,
        duration: (duration: number) => `duration: ${duration}ms`,
      }
    })
  : process.stdout

// Create Pino logger instance (for app logging with console output)
export const logger = pino({
  level: isDevelopment ? 'debug' : 'info',
  formatters: {
    level: (label) => {
      return { level: label }
    }
  },
  timestamp: pino.stdTimeFunctions.isoTime,
}, pino.multistream([
  // Console output (pretty in dev, JSON in prod)
  { 
    level: 'debug',
    stream: consoleStream
  },
  // PostgreSQL output (info and above)
  { 
    level: 'info',
    stream: postgresStream as any
  }
]))

// Create a silent logger for HTTP requests (database only, no console spam)
export const httpLogger = pino({
  level: 'info',
  formatters: {
    level: (label) => {
      return { level: label }
    }
  },
  timestamp: pino.stdTimeFunctions.isoTime,
}, pino.multistream([
  // PostgreSQL output only (no console)
  { 
    level: 'info',
    stream: postgresStream as any
  }
]))

// Helper function to create child logger with context
export function createLoggerWithContext(context: { 
  userId?: string
  endpoint?: string
  method?: string
}) {
  return logger.child(context)
}

// Helper to log errors with full stack traces
export function logError(error: Error, context?: Record<string, any>) {
  logger.error({
    ...context,
    error: error.message,
    stack: error.stack,
  }, error.message)
}
