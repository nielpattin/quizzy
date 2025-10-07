export interface User {
  id: string
  email: string
  displayName: string
  createdAt: Date
}

export interface Quiz {
  id: string
  title: string
  description: string
  createdBy: string
  createdAt: Date
  updatedAt: Date
}

export interface ApiResponse<T> {
  data?: T
  error?: string
  success: boolean
}
