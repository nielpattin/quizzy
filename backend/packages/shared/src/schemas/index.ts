import { z } from "zod"

export const userSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  displayName: z.string(),
  createdAt: z.date()
})

export const quizSchema = z.object({
  id: z.string(),
  title: z.string().min(1),
  description: z.string(),
  createdBy: z.string(),
  createdAt: z.date(),
  updatedAt: z.date()
})

export const createQuizSchema = z.object({
  title: z.string().min(1, "Title is required"),
  description: z.string()
})
