import type { ApiResponse } from "../types"

export function createSuccessResponse<T>(data: T): ApiResponse<T> {
  return {
    data,
    success: true
  }
}

export function createErrorResponse(error: string): ApiResponse<never> {
  return {
    error,
    success: false
  }
}
