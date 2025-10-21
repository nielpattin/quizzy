import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import type { AuthContext } from '../middleware/auth'
import { db } from '../db/index'
import { images } from '../db/schema'
import { eq, desc } from 'drizzle-orm'
import { validateImageFile, generateUniqueFilename, getS3File, getMimeTypeFromExtension, BUCKETS, ALLOWED_TYPES } from '../lib/s3'

type Variables = {
  user: AuthContext
}

const uploadRoutes = new Hono<{ Variables: Variables }>()

uploadRoutes.post('/image', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext

  try {
    const body = await c.req.parseBody()
    const file = body['image']

    if (!file || !(file instanceof File)) {
      return c.json({ error: 'No image file provided' }, 400)
    }

    const validationError = validateImageFile(file)
    if (validationError) {
      return c.json(validationError, 400)
    }

    const filename = generateUniqueFilename(file.name)
    const buffer = Buffer.from(await file.arrayBuffer())

    const detectedMimeType = getMimeTypeFromExtension(filename)
    const mimeType = ALLOWED_TYPES.includes(file.type) ? file.type : detectedMimeType

    const s3File = getS3File(filename)
    await s3File.write(buffer, {
      type: mimeType
    })

    const [image] = await db.insert(images).values({
      userId,
      filename,
      originalName: file.name,
      mimeType: mimeType,
      size: file.size,
      bucket: BUCKETS.DEFAULT
    }).returning()

    const url = s3File.presign({
      expiresIn: 24 * 60 * 60
    })

    return c.json({
      success: true,
      image: {
        id: image.id,
        filename: image.filename,
        url
      }
    }, 201)
  } catch (error) {
    console.error('Upload error:', error)
    return c.json({ error: 'Failed to upload image' }, 500)
  }
})

uploadRoutes.get('/image/:id/url', authMiddleware, async (c) => {
  const imageId = c.req.param('id')

  try {
    const [image] = await db
      .select()
      .from(images)
      .where(eq(images.id, imageId))

    if (!image) {
      return c.json({ error: 'Image not found' }, 404)
    }

    const s3File = getS3File(image.filename, image.bucket as any)
    const url = s3File.presign({
      expiresIn: 60 * 60
    })

    return c.json({ url })
  } catch (error) {
    console.error('Get URL error:', error)
    return c.json({ error: 'Failed to generate URL' }, 500)
  }
})

uploadRoutes.get('/image/:id/download', async (c) => {
  const imageId = c.req.param('id')

  try {
    const [image] = await db
      .select()
      .from(images)
      .where(eq(images.id, imageId))

    if (!image) {
      return c.json({ error: 'Image not found' }, 404)
    }

    const s3File = getS3File(image.filename, image.bucket as any)
    const stream = s3File.stream()

    return new Response(stream, {
      headers: {
        'Content-Type': image.mimeType,
        'Content-Disposition': `inline; filename="${image.originalName}"`
      }
    })
  } catch (error) {
    console.error('Download error:', error)
    return c.json({ error: 'Failed to download image' }, 500)
  }
})

uploadRoutes.get('/images', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const limit = parseInt(c.req.query('limit') || '20')
  const offset = parseInt(c.req.query('offset') || '0')

  try {
    const userImages = await db
      .select()
      .from(images)
      .where(eq(images.userId, userId))
      .orderBy(desc(images.createdAt))
      .limit(limit)
      .offset(offset)

    return c.json({ images: userImages })
  } catch (error) {
    console.error('List images error:', error)
    return c.json({ error: 'Failed to list images' }, 500)
  }
})

uploadRoutes.delete('/image/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const imageId = c.req.param('id')

  try {
    const [image] = await db
      .select()
      .from(images)
      .where(eq(images.id, imageId))

    if (!image) {
      return c.json({ error: 'Image not found' }, 404)
    }

    if (image.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    const s3File = getS3File(image.filename, image.bucket as any)
    await s3File.delete()

    await db.delete(images).where(eq(images.id, imageId))

    return c.json({ success: true, message: 'Image deleted' })
  } catch (error) {
    console.error('Delete error:', error)
    return c.json({ error: 'Failed to delete image' }, 500)
  }
})

export default uploadRoutes
