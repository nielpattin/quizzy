import * as Minio from 'minio'
import { BUCKETS } from '../server/lib/s3'

const S3_ENDPOINT = Bun.env.S3_ENDPOINT || 'http://localhost:9000'
const S3_ACCESS_KEY_ID = Bun.env.S3_ACCESS_KEY_ID || 'minioadmin'
const S3_SECRET_ACCESS_KEY = Bun.env.S3_SECRET_ACCESS_KEY || 'minioadmin123'

const parseEndpoint = (endpoint: string) => {
  const url = new URL(endpoint)
  return {
    endPoint: url.hostname,
    port: url.port ? parseInt(url.port) : (url.protocol === 'https:' ? 443 : 9000),
    useSSL: url.protocol === 'https:'
  }
}

const createMinioClient = () => {
  const { endPoint, port, useSSL } = parseEndpoint(S3_ENDPOINT)
  return new Minio.Client({
    endPoint,
    port,
    useSSL,
    accessKey: S3_ACCESS_KEY_ID,
    secretKey: S3_SECRET_ACCESS_KEY
  })
}

export const cleanMinIOBuckets = async () => {
  console.log('🧹 Cleaning MinIO buckets...')

  try {
    const minioClient = createMinioClient()
    const requiredBuckets = Object.values(BUCKETS)

    for (const bucketName of requiredBuckets) {
      try {
        const exists = await minioClient.bucketExists(bucketName)
        
        if (!exists) {
          console.log(`  ⏭️  Bucket '${bucketName}' doesn't exist, skipping...`)
          continue
        }

        const objectsList: string[] = []
        const objectsStream = minioClient.listObjectsV2(bucketName, '', true)
        
        for await (const obj of objectsStream) {
          if (obj.name) {
            objectsList.push(obj.name)
          }
        }

        if (objectsList.length > 0) {
          await minioClient.removeObjects(bucketName, objectsList)
          console.log(`  ✓ Cleaned ${objectsList.length} objects from '${bucketName}'`)
        } else {
          console.log(`  ✓ Bucket '${bucketName}' is already empty`)
        }
      } catch (error) {
        console.error(`  ❌ Error cleaning bucket '${bucketName}':`, error)
        throw error
      }
    }

    console.log('✅ MinIO buckets cleaned!')
  } catch (error) {
    console.error('❌ MinIO cleanup failed:', error)
    console.error('\n💡 Make sure MinIO is running: cd backend && docker compose up -d minio')
    throw error
  }
}

const setupMinIO = async () => {
  console.log('🪣 Setting up MinIO buckets...')

  try {
    const minioClient = createMinioClient()
    const requiredBuckets = Object.values(BUCKETS)

    console.log(`📋 Checking ${requiredBuckets.length} buckets...`)

    for (const bucketName of requiredBuckets) {
      try {
        const exists = await minioClient.bucketExists(bucketName)
        
        if (exists) {
          console.log(`✓ Bucket '${bucketName}' already exists`)
        } else {
          await minioClient.makeBucket(bucketName, 'us-east-1')
          console.log(`✓ Created bucket '${bucketName}'`)
        }
      } catch (error) {
        console.error(`❌ Error processing bucket '${bucketName}':`, error)
        throw error
      }
    }

    console.log('✅ MinIO setup complete!')
  } catch (error) {
    console.error('❌ MinIO setup failed:', error)
    console.error('\n💡 Make sure MinIO is running: cd backend && docker compose up -d minio')
    process.exit(1)
  }
}

setupMinIO().catch((error) => {
  console.error('Fatal error:', error)
  process.exit(1)
})
