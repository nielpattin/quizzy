import { Hono } from 'hono'
import { authMiddleware, optionalAuthMiddleware } from '../middleware/auth'
import type { AuthContext } from '../middleware/auth'
import { db } from '../db/index'
import { posts, postLikes, comments, commentLikes, users, postAnswers } from '../db/schema'
import { eq, and, desc, inArray, sql } from 'drizzle-orm'
import { NotificationService } from '../services/notification-service'
import { rateLimitLikes } from '../middleware/rate-limiter'

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

    const postType = body.postType || 'text'
    
    if (postType === 'quiz') {
      if (!body.questionType || !body.questionText || !body.questionData) {
        return c.json({ error: 'Quiz posts require questionType, questionText, and questionData' }, 400)
      }
      
      if (!body.questionData.options || !Array.isArray(body.questionData.options) || body.questionData.options.length < 2) {
        return c.json({ error: 'questionData must have at least 2 options' }, 400)
      }
      
      if (body.questionData.correctAnswer === undefined) {
        return c.json({ error: 'questionData must have correctAnswer' }, 400)
      }
    }

    const [newPost] = await db
      .insert(posts)
      .values({
        userId,
        text: body.text,
        postType: postType,
        imageUrl: body.imageUrl || null,
        questionType: body.questionType || null,
        questionText: body.questionText || null,
        questionData: body.questionData || null,
      })
      .returning()

    return c.json(newPost, 201)
  } catch (error) {
    console.error('Error creating post:', error)
    return c.json({ error: 'Failed to create post' }, 500)
  }
})

socialRoutes.get('/posts', optionalAuthMiddleware, async (c) => {
  const limit = parseInt(c.req.query('limit') || '20')
  const offset = parseInt(c.req.query('offset') || '0')
  const user = c.get('user') as AuthContext | undefined
  const userId = user?.userId

  try {
    const feedPosts = await db
      .select({
        id: posts.id,
        text: posts.text,
        postType: posts.postType,
        imageUrl: posts.imageUrl,
        questionType: posts.questionType,
        questionText: posts.questionText,
        questionData: posts.questionData,
        answersCount: posts.answersCount,
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

    if (userId && feedPosts.length > 0) {
      const postIds = feedPosts.map(p => p.id)
      
      const likes = await db
        .select({ postId: postLikes.postId })
        .from(postLikes)
        .where(and(
          eq(postLikes.userId, userId),
          inArray(postLikes.postId, postIds)
        ))
      
      const answers = await db
        .select({ 
          postId: postAnswers.postId,
          isCorrect: postAnswers.isCorrect 
        })
        .from(postAnswers)
        .where(and(
          eq(postAnswers.userId, userId),
          inArray(postAnswers.postId, postIds)
        ))
      
      const correctAnswersCount = await db
        .select({
          postId: postAnswers.postId,
          count: sql<number>`count(*)::int`.as('count')
        })
        .from(postAnswers)
        .where(and(
          inArray(postAnswers.postId, postIds),
          eq(postAnswers.isCorrect, true)
        ))
        .groupBy(postAnswers.postId)
      
      const likedPostIds = new Set(likes.map(l => l.postId))
      const answeredPostsMap = new Map(answers.map(a => [a.postId, a.isCorrect]))
      const correctCountMap = new Map(correctAnswersCount.map(c => [c.postId, c.count]))
      
      const postsWithData = feedPosts.map(post => {
        const hasAnswered = answeredPostsMap.has(post.id)
        const userIsCorrect = answeredPostsMap.get(post.id) || false
        const correctCount = correctCountMap.get(post.id) || 0
        const correctPercentage = post.answersCount > 0 ? (correctCount / post.answersCount) * 100 : 0
        
        return {
          ...post,
          isLiked: likedPostIds.has(post.id),
          hasAnswered,
          userIsCorrect,
          correctPercentage
        }
      })
      
      return c.json(postsWithData)
    }

    return c.json(feedPosts.map(post => ({ 
      ...post, 
      isLiked: false,
      hasAnswered: false,
      userIsCorrect: false,
      correctPercentage: 0
    })))
  } catch (error) {
    console.error('Error fetching posts:', error)
    return c.json({ error: 'Failed to fetch posts' }, 500)
  }
})

socialRoutes.get('/posts/:id', optionalAuthMiddleware, async (c) => {
  const postId = c.req.param('id')
  const user = c.get('user') as AuthContext | undefined
  const userId = user?.userId

  try {
    const [post] = await db
      .select({
        id: posts.id,
        text: posts.text,
        postType: posts.postType,
        imageUrl: posts.imageUrl,
        questionType: posts.questionType,
        questionText: posts.questionText,
        questionData: posts.questionData,
        answersCount: posts.answersCount,
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

    if (userId) {
      const [like] = await db
        .select()
        .from(postLikes)
        .where(and(
          eq(postLikes.userId, userId),
          eq(postLikes.postId, postId)
        ))
      
      const [answer] = await db
        .select({ isCorrect: postAnswers.isCorrect })
        .from(postAnswers)
        .where(and(
          eq(postAnswers.userId, userId),
          eq(postAnswers.postId, postId)
        ))
      
      const [correctCount] = await db
        .select({
          count: sql<number>`count(*)::int`.as('count')
        })
        .from(postAnswers)
        .where(and(
          eq(postAnswers.postId, postId),
          eq(postAnswers.isCorrect, true)
        ))
      
      const correctPercentage = post.answersCount > 0 ? ((correctCount?.count || 0) / post.answersCount) * 100 : 0
      
      return c.json({ 
        ...post, 
        isLiked: !!like,
        hasAnswered: !!answer,
        userIsCorrect: answer?.isCorrect || false,
        correctPercentage
      })
    }

    return c.json({ 
      ...post, 
      isLiked: false,
      hasAnswered: false,
      userIsCorrect: false,
      correctPercentage: 0
    })
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

socialRoutes.post('/posts/:id/like', authMiddleware, rateLimitLikes, async (c) => {
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

    // Create notification for post like
    await NotificationService.createPostLikeNotification(userId, postId)

    return c.json(newLike, 201)
  } catch (error) {
    console.error('Error liking post:', error)
    return c.json({ error: 'Failed to like post' }, 500)
  }
})

socialRoutes.delete('/posts/:id/like', authMiddleware, rateLimitLikes, async (c) => {
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

    // Create notification for new comment
    await NotificationService.createCommentNotification(userId, postId)

    return c.json(newComment, 201)
  } catch (error) {
    console.error('Error creating comment:', error)
    return c.json({ error: 'Failed to create comment' }, 500)
  }
})

socialRoutes.get('/posts/:id/comments', optionalAuthMiddleware, async (c) => {
  const postId = c.req.param('id')
  const user = c.get('user') as AuthContext | undefined
  const userId = user?.userId

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

    if (userId && postComments.length > 0) {
      const commentIds = postComments.map(c => c.id)
      const likes = await db
        .select({ commentId: commentLikes.commentId })
        .from(commentLikes)
        .where(and(
          eq(commentLikes.userId, userId),
          inArray(commentLikes.commentId, commentIds)
        ))
      
      const likedCommentIds = new Set(likes.map(l => l.commentId))
      
      const commentsWithLikes = postComments.map(comment => ({
        ...comment,
        isLiked: likedCommentIds.has(comment.id)
      }))
      
      return c.json(commentsWithLikes)
    }

    return c.json(postComments.map(comment => ({ ...comment, isLiked: false })))
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
        postType: posts.postType,
        imageUrl: posts.imageUrl,
        questionType: posts.questionType,
        questionText: posts.questionText,
        questionData: posts.questionData,
        answersCount: posts.answersCount,
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

socialRoutes.post('/posts/:id/answer', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const postId = c.req.param('id')
  const body = await c.req.json()

  try {
    const [post] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, postId))

    if (!post) {
      return c.json({ error: 'Post not found' }, 404)
    }

    if (post.postType !== 'quiz') {
      return c.json({ error: 'This post is not a quiz' }, 400)
    }

    const [existingAnswer] = await db
      .select()
      .from(postAnswers)
      .where(and(
        eq(postAnswers.postId, postId),
        eq(postAnswers.userId, userId)
      ))

    if (existingAnswer) {
      return c.json({ error: 'You have already answered this quiz' }, 400)
    }

    if (body.answer === undefined) {
      return c.json({ error: 'answer is required' }, 400)
    }

    const questionData = post.questionData as { options: string[], correctAnswer: number | number[] }
    let isCorrect = false

    if (Array.isArray(questionData.correctAnswer)) {
      const userAnswer = Array.isArray(body.answer) ? body.answer.sort() : [body.answer]
      const correctAnswer = [...questionData.correctAnswer].sort()
      isCorrect = JSON.stringify(userAnswer) === JSON.stringify(correctAnswer)
    } else {
      isCorrect = body.answer === questionData.correctAnswer
    }

    await db.insert(postAnswers).values({
      postId,
      userId,
      answer: body.answer,
      isCorrect,
    })

    await db
      .update(posts)
      .set({
        answersCount: post.answersCount + 1,
      })
      .where(eq(posts.id, postId))

    // Create notification for quiz answer
    await NotificationService.createQuizAnswerNotification(userId, postId)

    const [correctCount] = await db
      .select({
        count: sql<number>`count(*)::int`.as('count')
      })
      .from(postAnswers)
      .where(and(
        eq(postAnswers.postId, postId),
        eq(postAnswers.isCorrect, true)
      ))

    const totalAnswers = post.answersCount + 1
    const correctPercentage = ((correctCount?.count || 0) / totalAnswers) * 100

    return c.json({
      isCorrect,
      correctAnswer: questionData.correctAnswer,
      answersCount: totalAnswers,
      correctPercentage
    }, 201)
  } catch (error) {
    console.error('Error submitting answer:', error)
    return c.json({ error: 'Failed to submit answer' }, 500)
  }
})

export default socialRoutes
