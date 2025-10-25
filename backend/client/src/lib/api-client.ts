import { supabase } from "./supabase";

export class AuthError extends Error {
	constructor(
		message: string,
		public status: number,
	) {
		super(message);
		this.name = "AuthError";
	}
}

export async function fetchWithAuth(
	url: string,
	options: RequestInit = {},
): Promise<Response> {
	const {
		data: { session },
	} = await supabase.auth.getSession();

	if (!session) {
		throw new AuthError("No active session", 401);
	}

	const headers = {
		...options.headers,
		Authorization: `Bearer ${session.access_token}`,
	};

	const response = await fetch(url, {
		...options,
		headers,
	});

	if (response.status === 401 || response.status === 403) {
		await supabase.auth.signOut();

		throw new AuthError(
			response.status === 401
				? "Session expired or invalid"
				: "Access forbidden - insufficient permissions",
			response.status,
		);
	}

	return response;
}

export async function apiGet<T>(url: string): Promise<T> {
	const response = await fetchWithAuth(url);

	if (!response.ok) {
		const errorData = await response.json().catch(() => ({}));
		throw new Error(errorData.error || "Request failed");
	}

	return response.json();
}

export async function apiPost<T>(url: string, data?: unknown): Promise<T> {
	const response = await fetchWithAuth(url, {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: data ? JSON.stringify(data) : undefined,
	});

	if (!response.ok) {
		const errorData = await response.json().catch(() => ({}));
		throw new Error(errorData.error || "Request failed");
	}

	return response.json();
}

export async function apiPut<T>(url: string, data?: unknown): Promise<T> {
	const response = await fetchWithAuth(url, {
		method: "PUT",
		headers: {
			"Content-Type": "application/json",
		},
		body: data ? JSON.stringify(data) : undefined,
	});

	if (!response.ok) {
		const errorData = await response.json().catch(() => ({}));
		throw new Error(errorData.error || "Request failed");
	}

	return response.json();
}

export async function apiDelete<T>(url: string): Promise<T> {
	const response = await fetchWithAuth(url, {
		method: "DELETE",
	});

	if (!response.ok) {
		const errorData = await response.json().catch(() => ({}));
		throw new Error(errorData.error || "Request failed");
	}

	return response.json();
}
