export type RpcRoute = {
  path: string
  method: "GET" | "POST" | "PUT" | "DELETE" | "PATCH"
}

export const API_ROUTES = {
  HEALTH: "/api/health",
  QUIZZES: "/api/quizzes",
  QUIZ_BY_ID: (id: string) => `/api/quizzes/${id}`
} as const
