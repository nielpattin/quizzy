import { Hono } from 'hono'
import { authMiddleware, type AuthContext } from '../middleware/auth'
import { db } from '../db/index'
import { questions, quizzes } from '../db/schema'
import { eq, and } from 'drizzle-orm'
import { WebSocketService } from '../services/websocket-service'

type Variables = {
  user: AuthContext
}

const questionRoutes = new Hono<{ Variables: Variables }>()

questionRoutes.post('/', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    if (!body.quizId || !body.type || !body.questionText || !body.data) {
      return c.json({ error: 'quizId, type, questionText, and data are required' }, 400)
    }

    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, body.quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    if (quiz.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    const maxOrderIndex = await db
      .select({ max: questions.orderIndex })
      .from(questions)
      .where(eq(questions.quizId, body.quizId))

    const orderIndex = body.orderIndex !== undefined 
      ? body.orderIndex 
      : (maxOrderIndex[0]?.max !== null ? maxOrderIndex[0].max + 1 : 0)

    const [newQuestion] = await db
      .insert(questions)
      .values({
        quizId: body.quizId,
        type: body.type,
        questionText: body.questionText,
        data: body.data,
        orderIndex,
      })
      .returning()

    await db
      .update(quizzes)
      .set({
        questionCount: quiz.questionCount + 1,
        updatedAt: new Date(),
      })
      .where(eq(quizzes.id, body.quizId))

    return c.json(newQuestion, 201)
  } catch (error) {
    console.error('Error creating question:', error)
    return c.json({ error: 'Failed to create question' }, 500)
  }
})

questionRoutes.get('/:id', async (c) => {
  const questionId = c.req.param('id')

  try {
    const [question] = await db
      .select()
      .from(questions)
      .where(eq(questions.id, questionId))

    if (!question) {
      return c.json({ error: 'Question not found' }, 404)
    }

    return c.json(question)
  } catch (error) {
    console.error('Error fetching question:', error)
    return c.json({ error: 'Failed to fetch question' }, 500)
  }
})

questionRoutes.put('/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const questionId = c.req.param('id')
  const body = await c.req.json()

  try {
    const [existingQuestion] = await db
      .select()
      .from(questions)
      .where(eq(questions.id, questionId))

    if (!existingQuestion) {
      return c.json({ error: 'Question not found' }, 404)
    }

    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, existingQuestion.quizId), eq(quizzes.isDeleted, false)))

    if (!quiz || quiz.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    const [updatedQuestion] = await db
      .update(questions)
      .set({
        type: body.type,
        questionText: body.questionText,
        data: body.data,
        orderIndex: body.orderIndex,
      })
      .where(eq(questions.id, questionId))
      .returning()

    await db
      .update(quizzes)
      .set({ updatedAt: new Date() })
      .where(eq(quizzes.id, existingQuestion.quizId))

    return c.json(updatedQuestion)
  } catch (error) {
    console.error('Error updating question:', error)
    return c.json({ error: 'Failed to update question' }, 500)
  }
})

questionRoutes.delete('/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const questionId = c.req.param('id')

  try {
    const [existingQuestion] = await db
      .select()
      .from(questions)
      .where(eq(questions.id, questionId))

    if (!existingQuestion) {
      return c.json({ error: 'Question not found' }, 404)
    }

    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, existingQuestion.quizId), eq(quizzes.isDeleted, false)))

    if (!quiz || quiz.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    await db
      .delete(questions)
      .where(eq(questions.id, questionId))

    await db
      .update(quizzes)
      .set({
        questionCount: Math.max(0, quiz.questionCount - 1),
        updatedAt: new Date(),
      })
      .where(eq(quizzes.id, existingQuestion.quizId))

    return c.json({ message: 'Question deleted successfully' })
  } catch (error) {
    console.error('Error deleting question:', error)
    return c.json({ error: 'Failed to delete question' }, 500)
  }
})

questionRoutes.post('/bulk', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    if (!body.quizId || !Array.isArray(body.questions) || body.questions.length === 0) {
      return c.json({ error: 'quizId and questions array are required' }, 400)
    }

    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, body.quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    if (quiz.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    const questionsToInsert = body.questions.map((q: any, index: number) => ({
      quizId: body.quizId,
      type: q.type,
      questionText: q.questionText,
      data: q.data,
      orderIndex: q.orderIndex !== undefined ? q.orderIndex : index,
    }))

    const newQuestions = await db
      .insert(questions)
      .values(questionsToInsert)
      .returning()

    await db
      .update(quizzes)
      .set({
        questionCount: quiz.questionCount + newQuestions.length,
        updatedAt: new Date(),
      })
      .where(eq(quizzes.id, body.quizId))

    return c.json(newQuestions, 201)
  } catch (error) {
    console.error('Error creating bulk questions:', error)
    return c.json({ error: 'Failed to create questions' }, 500)
  }
})

export default questionRoutes
