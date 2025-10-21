import { s3 } from 'bun'
import { randomUUID } from 'crypto'

export const MAX_FILE_SIZE = 5 * 1024 * 1024
export const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif']

export const BUCKETS = {
  PROFILES: 'user-profiles',
  POSTS: 'post-images',
  QUIZZES: 'quiz-images',
  DEFAULT: 'quizzy-images'
} as const

export type BucketName = typeof BUCKETS[keyof typeof BUCKETS]

export interface ValidationError {
  error: string
}

export function validateImageFile(
  file: File,
  maxSize: number = MAX_FILE_SIZE,
  allowedTypes: string[] = ALLOWED_TYPES
): ValidationError | null {
  if (file.size > maxSize) {
    return { error: `File too large. Maximum size is ${maxSize / 1024 / 1024}MB` }
  }

  if (!allowedTypes.includes(file.type)) {
    const ext = file.name.split('.').pop()?.toLowerCase()
    const validExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif']
    
    if (!ext || !validExtensions.includes(ext)) {
      return { error: `Invalid file type. Allowed types: ${allowedTypes.join(', ')}. Received: ${file.type || 'unknown'}, extension: ${ext || 'none'}` }
    }
    
    console.log(`⚠️ File type '${file.type}' not in allowed list, but extension '.${ext}' is valid - allowing upload`)
  }

  return null
}

export function generateUniqueFilename(originalName: string): string {
  const ext = originalName.split('.').pop() || 'jpg'
  return `${randomUUID()}.${ext}`
}

export function getMimeTypeFromExtension(filename: string): string {
  const ext = filename.split('.').pop()?.toLowerCase()
  const mimeTypes: Record<string, string> = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif'
  }
  return mimeTypes[ext || ''] || 'image/jpeg'
}

export function getS3File(filename: string, bucket: BucketName = BUCKETS.DEFAULT) {
  const credentials = {
    bucket,
    accessKeyId: Bun.env.S3_ACCESS_KEY_ID || process.env.S3_ACCESS_KEY_ID,
    secretAccessKey: Bun.env.S3_SECRET_ACCESS_KEY || process.env.S3_SECRET_ACCESS_KEY,
    endpoint: Bun.env.S3_ENDPOINT || process.env.S3_ENDPOINT,
  }
  
  console.log('🔑 S3 Credentials check:', {
    hasAccessKey: !!credentials.accessKeyId,
    hasSecretKey: !!credentials.secretAccessKey,
    hasEndpoint: !!credentials.endpoint,
    hasBucket: !!credentials.bucket,
    endpoint: credentials.endpoint
  })
  
  if (!credentials.accessKeyId || !credentials.secretAccessKey || !credentials.endpoint) {
    throw new Error('Missing S3 credentials in environment variables')
  }
  
  return s3.file(filename, credentials)
}
