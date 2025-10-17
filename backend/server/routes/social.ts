import { Hono } from 'hono'
import { authMiddleware } from '@/middleware/auth'
import type { AuthContext } from '@/middleware/auth'
import { db } from '@/db'
import { posts, postLikes, comments, commentLikes, users } from '@/db/schema'
import { eq, and, desc } from 'drizzle-orm'

type Variables = {
  user: AuthContext
}

const socialRoutes = new Hono<{ Variables: Variables }>()

socialRoutes.post('/posts', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    if (!body.text || body.text.trim() === '') {
      return c.json({ error: 'Post text is required' }, 400)
    }

    const [newPost] = await db
      .insert(posts)
      .values({
        userId,
        text: body.text,
      })
      .returning()

    return c.json(newPost, 201)
  } catch (error) {
    console.error('Error creating post:', error)
    return c.json({ error: 'Failed to create post' }, 500)
  }
})

socialRoutes.get('/posts', async (c) => {
  const limit = parseInt(c.req.query('limit') || '20')
  const offset = parseInt(c.req.query('offset') || '0')

  try {
    const feedPosts = await db
      .select({
        id: posts.id,
        text: posts.text,
        likesCount: posts.likesCount,
        commentsCount: posts.commentsCount,
        createdAt: posts.createdAt,
        updatedAt: posts.updatedAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(posts)
      .leftJoin(users, eq(posts.userId, users.id))
      .orderBy(desc(posts.createdAt))
      .limit(limit)
      .offset(offset)

    return c.json(feedPosts)
  } catch (error) {
    console.error('Error fetching posts:', error)
    return c.json({ error: 'Failed to fetch posts' }, 500)
  }
})

socialRoutes.get('/posts/:id', async (c) => {
  const postId = c.req.param('id')

  try {
    const [post] = await db
      .select({
        id: posts.id,
        text: posts.text,
        likesCount: posts.likesCount,
        commentsCount: posts.commentsCount,
        createdAt: posts.createdAt,
        updatedAt: posts.updatedAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(posts)
      .leftJoin(users, eq(posts.userId, users.id))
      .where(eq(posts.id, postId))

    if (!post) {
      return c.json({ error: 'Post not found' }, 404)
    }

    return c.json(post)
  } catch (error) {
    console.error('Error fetching post:', error)
    return c.json({ error: 'Failed to fetch post' }, 500)
  }
})

socialRoutes.put('/posts/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const postId = c.req.param('id')
  const body = await c.req.json()

  try {
    const [existingPost] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, postId))

    if (!existingPost) {
      return c.json({ error: 'Post not found' }, 404)
    }

    if (existingPost.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    if (!body.text || body.text.trim() === '') {
      return c.json({ error: 'Post text is required' }, 400)
    }

    const [updatedPost] = await db
      .update(posts)
      .set({
        text: body.text,
        updatedAt: new Date(),
      })
      .where(eq(posts.id, postId))
      .returning()

    return c.json(updatedPost)
  } catch (error) {
    console.error('Error updating post:', error)
    return c.json({ error: 'Failed to update post' }, 500)
  }
})

socialRoutes.delete('/posts/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const postId = c.req.param('id')

  try {
    const [existingPost] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, postId))

    if (!existingPost) {
      return c.json({ error: 'Post not found' }, 404)
    }

    if (existingPost.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    await db
      .delete(posts)
      .where(eq(posts.id, postId))

    return c.json({ message: 'Post deleted successfully' })
  } catch (error) {
    console.error('Error deleting post:', error)
    return c.json({ error: 'Failed to delete post' }, 500)
  }
})

socialRoutes.post('/posts/:id/like', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const postId = c.req.param('id')

  try {
    const [post] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, postId))

    if (!post) {
      return c.json({ error: 'Post not found' }, 404)
    }

    const [existingLike] = await db
      .select()
      .from(postLikes)
      .where(and(
        eq(postLikes.userId, userId),
        eq(postLikes.postId, postId)
      ))

    if (existingLike) {
      return c.json({ message: 'Already liked this post' }, 200)
    }

    const [newLike] = await db
      .insert(postLikes)
      .values({
        userId,
        postId,
      })
      .returning()

    await db
      .update(posts)
      .set({
        likesCount: post.likesCount + 1,
      })
      .where(eq(posts.id, postId))

    return c.json(newLike, 201)
  } catch (error) {
    console.error('Error liking post:', error)
    return c.json({ error: 'Failed to like post' }, 500)
  }
})

socialRoutes.delete('/posts/:id/like', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const postId = c.req.param('id')

  try {
    const [existingLike] = await db
      .select()
      .from(postLikes)
      .where(and(
        eq(postLikes.userId, userId),
        eq(postLikes.postId, postId)
      ))

    if (!existingLike) {
      return c.json({ error: 'Like not found' }, 404)
    }

    await db
      .delete(postLikes)
      .where(and(
        eq(postLikes.userId, userId),
        eq(postLikes.postId, postId)
      ))

    const [post] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, postId))

    if (post) {
      await db
        .update(posts)
        .set({
          likesCount: Math.max(0, post.likesCount - 1),
        })
        .where(eq(posts.id, postId))
    }

    return c.json({ message: 'Post unliked successfully' })
  } catch (error) {
    console.error('Error unliking post:', error)
    return c.json({ error: 'Failed to unlike post' }, 500)
  }
})

socialRoutes.post('/posts/:id/comments', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const postId = c.req.param('id')
  const body = await c.req.json()

  try {
    if (!body.content || body.content.trim() === '') {
      return c.json({ error: 'Comment content is required' }, 400)
    }

    const [post] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, postId))

    if (!post) {
      return c.json({ error: 'Post not found' }, 404)
    }

    const [newComment] = await db
      .insert(comments)
      .values({
        postId,
        userId,
        content: body.content,
      })
      .returning()

    await db
      .update(posts)
      .set({
        commentsCount: post.commentsCount + 1,
      })
      .where(eq(posts.id, postId))

    return c.json(newComment, 201)
  } catch (error) {
    console.error('Error creating comment:', error)
    return c.json({ error: 'Failed to create comment' }, 500)
  }
})

socialRoutes.get('/posts/:id/comments', async (c) => {
  const postId = c.req.param('id')

  try {
    const postComments = await db
      .select({
        id: comments.id,
        content: comments.content,
        likesCount: comments.likesCount,
        createdAt: comments.createdAt,
        updatedAt: comments.updatedAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(comments)
      .leftJoin(users, eq(comments.userId, users.id))
      .where(eq(comments.postId, postId))
      .orderBy(desc(comments.createdAt))

    return c.json(postComments)
  } catch (error) {
    console.error('Error fetching comments:', error)
    return c.json({ error: 'Failed to fetch comments' }, 500)
  }
})

socialRoutes.delete('/comments/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const commentId = c.req.param('id')

  try {
    const [existingComment] = await db
      .select()
      .from(comments)
      .where(eq(comments.id, commentId))

    if (!existingComment) {
      return c.json({ error: 'Comment not found' }, 404)
    }

    if (existingComment.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    await db
      .delete(comments)
      .where(eq(comments.id, commentId))

    const [post] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, existingComment.postId))

    if (post) {
      await db
        .update(posts)
        .set({
          commentsCount: Math.max(0, post.commentsCount - 1),
        })
        .where(eq(posts.id, existingComment.postId))
    }

    return c.json({ message: 'Comment deleted successfully' })
  } catch (error) {
    console.error('Error deleting comment:', error)
    return c.json({ error: 'Failed to delete comment' }, 500)
  }
})

socialRoutes.post('/comments/:id/like', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const commentId = c.req.param('id')

  try {
    const [comment] = await db
      .select()
      .from(comments)
      .where(eq(comments.id, commentId))

    if (!comment) {
      return c.json({ error: 'Comment not found' }, 404)
    }

    const [existingLike] = await db
      .select()
      .from(commentLikes)
      .where(and(
        eq(commentLikes.userId, userId),
        eq(commentLikes.commentId, commentId)
      ))

    if (existingLike) {
      return c.json({ message: 'Already liked this comment' }, 200)
    }

    const [newLike] = await db
      .insert(commentLikes)
      .values({
        userId,
        commentId,
      })
      .returning()

    await db
      .update(comments)
      .set({
        likesCount: comment.likesCount + 1,
      })
      .where(eq(comments.id, commentId))

    return c.json(newLike, 201)
  } catch (error) {
    console.error('Error liking comment:', error)
    return c.json({ error: 'Failed to like comment' }, 500)
  }
})

socialRoutes.delete('/comments/:id/like', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const commentId = c.req.param('id')

  try {
    const [existingLike] = await db
      .select()
      .from(commentLikes)
      .where(and(
        eq(commentLikes.userId, userId),
        eq(commentLikes.commentId, commentId)
      ))

    if (!existingLike) {
      return c.json({ error: 'Like not found' }, 404)
    }

    await db
      .delete(commentLikes)
      .where(and(
        eq(commentLikes.userId, userId),
        eq(commentLikes.commentId, commentId)
      ))

    const [comment] = await db
      .select()
      .from(comments)
      .where(eq(comments.id, commentId))

    if (comment) {
      await db
        .update(comments)
        .set({
          likesCount: Math.max(0, comment.likesCount - 1),
        })
        .where(eq(comments.id, commentId))
    }

    return c.json({ message: 'Comment unliked successfully' })
  } catch (error) {
    console.error('Error unliking comment:', error)
    return c.json({ error: 'Failed to unlike comment' }, 500)
  }
})

socialRoutes.get('/user/:userId/posts', async (c) => {
  const targetUserId = c.req.param('userId')

  try {
    const userPosts = await db
      .select({
        id: posts.id,
        text: posts.text,
        likesCount: posts.likesCount,
        commentsCount: posts.commentsCount,
        createdAt: posts.createdAt,
        updatedAt: posts.updatedAt,
      })
      .from(posts)
      .where(eq(posts.userId, targetUserId))
      .orderBy(desc(posts.createdAt))

    return c.json(userPosts)
  } catch (error) {
    console.error('Error fetching user posts:', error)
    return c.json({ error: 'Failed to fetch user posts' }, 500)
  }
})

export default socialRoutes
