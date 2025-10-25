export const API_BASE_URL = import.meta.env.VITE_SERVER_URL;

if (!API_BASE_URL) {
	throw new Error(
		"VITE_SERVER_URL is not defined in environment variables. Please check your .env file.",
	);
}
