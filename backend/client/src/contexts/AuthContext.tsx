import type { Session, User } from "@supabase/supabase-js";
import {
	createContext,
	type ReactNode,
	useContext,
	useEffect,
	useState,
} from "react";
import { API_BASE_URL } from "../lib/constants";
import { supabase } from "../lib/supabase";

interface AuthContextType {
	session: Session | null;
	user: User | null;
	loading: boolean;
	signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Helper function to validate session with backend
async function validateSessionWithBackend(session: Session): Promise<boolean> {
	try {
		const response = await fetch(`${API_BASE_URL}/api/auth/check-admin`, {
			headers: { Authorization: `Bearer ${session.access_token}` },
		});

		if (response.status === 401 || response.status === 403) {
			console.warn(
				"[AUTH] Session validation failed: Invalid or insufficient permissions",
			);
			return false;
		}

		return true;
	} catch (error) {
		console.error("[AUTH] Error validating session:", error);
		// On network error, assume valid (don't block user on network issues)
		return true;
	}
}

export function AuthProvider({ children }: { children: ReactNode }) {
	const [session, setSession] = useState<Session | null>(null);
	const [user, setUser] = useState<User | null>(null);
	const [loading, setLoading] = useState(true);

	useEffect(() => {
		// Use ONLY onAuthStateChange to handle all session updates
		// This prevents race conditions between getSession() and the listener
		const {
			data: { subscription },
		} = supabase.auth.onAuthStateChange(async (_event, session) => {
			console.log(`[AUTH] Auth state changed: ${_event}`);

			// Validate session on INITIAL_SESSION or SIGNED_IN events
			if (session && (_event === "INITIAL_SESSION" || _event === "SIGNED_IN")) {
				const isValid = await validateSessionWithBackend(session);

				if (!isValid) {
					console.warn("[AUTH] Invalid session detected, signing out");
					await supabase.auth.signOut();
					// Don't set session state - SIGNED_OUT event will handle it
					return;
				}
			}

			// Update session state
			setSession(session);
			setUser(session?.user ?? null);
			setLoading(false);

			// Handle redirects for signed out users
			if (!session && typeof window !== "undefined") {
				const currentPath = window.location.pathname;
				if (currentPath !== "/login" && currentPath.startsWith("/admin")) {
					console.log("[AUTH] Session expired, redirecting to login");
					window.location.href = "/login";
				}
			}
		});

		return () => subscription.unsubscribe();
	}, []);

	const signOut = async () => {
		await supabase.auth.signOut();
		setSession(null);
		setUser(null);

		// Redirect to login
		if (typeof window !== "undefined") {
			window.location.href = "/login";
		}
	};

	const value = {
		session,
		user,
		loading,
		signOut,
	};

	return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
	const context = useContext(AuthContext);
	if (context === undefined) {
		throw new Error("useAuth must be used within an AuthProvider");
	}
	return context;
}
