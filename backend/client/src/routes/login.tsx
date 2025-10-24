import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { AlertCircle, Lock, Mail, User } from "lucide-react";
import { useCallback, useEffect, useId, useState } from "react";
import { useAuth } from "../contexts/AuthContext";
import { supabase } from "../lib/supabase";

export const Route = createFileRoute("/login")({
	component: LoginPage,
});

function LoginPage() {
	const navigate = useNavigate();
	const { session, loading: authLoading } = useAuth();
	const [hasAdmin, setHasAdmin] = useState<boolean | null>(null);
	const [loading, setLoading] = useState(false);
	const [error, setError] = useState("");
	const [isSignup, setIsSignup] = useState(false);

	const [email, setEmail] = useState("");
	const [password, setPassword] = useState("");
	const [confirmPassword, setConfirmPassword] = useState("");
	const [fullName, setFullName] = useState("");

	const fullNameId = useId();
	const emailId = useId();
	const passwordId = useId();
	const confirmPasswordId = useId();

	useEffect(() => {
		if (!authLoading && session) {
			navigate({ to: "/admin" });
		}
	}, [session, authLoading, navigate]);

	const checkAdminExists = useCallback(async () => {
		try {
			const response = await fetch(
				"http://localhost:8000/api/auth/check-admin",
			);
			const data = await response.json();
			setHasAdmin(data.hasAdmin);
			setIsSignup(!data.hasAdmin);
		} catch (err) {
			console.error("Failed to check admin existence:", err);
			setError("Failed to connect to server");
		}
	}, []);

	useEffect(() => {
		checkAdminExists();
	}, [checkAdminExists]);

	const handleSignup = async (e: React.FormEvent) => {
		e.preventDefault();
		setError("");
		setLoading(true);

		if (password !== confirmPassword) {
			setError("Passwords do not match");
			setLoading(false);
			return;
		}

		if (password.length < 6) {
			setError("Password must be at least 6 characters");
			setLoading(false);
			return;
		}

		try {
			const response = await fetch(
				"http://localhost:8000/api/auth/create-first-admin",
				{
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({ email, password, fullName }),
				},
			);

			const data = await response.json();

			if (!response.ok) {
				throw new Error(data.error || "Failed to create admin account");
			}

			if (data.session) {
				await supabase.auth.setSession({
					access_token: data.session.access_token,
					refresh_token: data.session.refresh_token,
				});
			}

			navigate({ to: "/admin" });
		} catch (err) {
			setError(err instanceof Error ? err.message : "Failed to create account");
		} finally {
			setLoading(false);
		}
	};

	const handleLogin = async (e: React.FormEvent) => {
		e.preventDefault();
		setError("");
		setLoading(true);

		try {
			const { data, error: signInError } =
				await supabase.auth.signInWithPassword({
					email,
					password,
				});

			if (signInError) {
				throw signInError;
			}

			if (data.session) {
				navigate({ to: "/admin" });
			}
		} catch (err) {
			setError(
				err instanceof Error ? err.message : "Invalid email or password",
			);
		} finally {
			setLoading(false);
		}
	};

	if (hasAdmin === null) {
		return (
			<div className="min-h-screen bg-[#0a0f1a] flex items-center justify-center">
				<div className="text-white">Loading...</div>
			</div>
		);
	}

	return (
		<div className="min-h-screen bg-[#0a0f1a] flex items-center justify-center p-6">
			<div className="w-full max-w-md">
				<div className="bg-[#1d293d] border border-[#314158] rounded-2xl p-8">
					<div className="text-center mb-8">
						<div className="bg-[#64a7ff] rounded-2xl shadow-lg size-16 flex items-center justify-center mx-auto mb-4">
							<Lock className="size-8 text-black" />
						</div>
						<h1 className="text-white text-3xl font-bold">QuizMaster</h1>
						<p className="text-[#8b9bab] mt-2">
							{isSignup ? "Create First Admin Account" : "Admin Login"}
						</p>
					</div>

					{error && (
						<div className="bg-[#e7000b]/10 border border-[#e7000b] rounded-lg p-3 mb-4 flex items-center gap-2">
							<AlertCircle className="size-4 text-[#e7000b] flex-shrink-0" />
							<p className="text-[#e7000b] text-sm">{error}</p>
						</div>
					)}

					<form onSubmit={isSignup ? handleSignup : handleLogin}>
						{isSignup && (
							<div className="mb-4">
								<label
									htmlFor={fullNameId}
									className="block text-[#cad5e2] text-sm mb-2"
								>
									Full Name
								</label>
								<div className="relative">
									<User className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-[#8b9bab]" />
									<input
										id={fullNameId}
										type="text"
										value={fullName}
										onChange={(e) => setFullName(e.target.value)}
										placeholder="Enter your full name"
										required
										className="w-full bg-[rgba(37,51,71,0.3)] border border-[#45556c] rounded-lg pl-10 pr-3 py-2.5 text-white placeholder-[#8b9bab] focus:outline-none focus:border-[#64a7ff]"
									/>
								</div>
							</div>
						)}

						<div className="mb-4">
							<label
								htmlFor={emailId}
								className="block text-[#cad5e2] text-sm mb-2"
							>
								Email
							</label>
							<div className="relative">
								<Mail className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-[#8b9bab]" />
								<input
									id={emailId}
									type="email"
									value={email}
									onChange={(e) => setEmail(e.target.value)}
									placeholder="Enter your email"
									required
									className="w-full bg-[rgba(37,51,71,0.3)] border border-[#45556c] rounded-lg pl-10 pr-3 py-2.5 text-white placeholder-[#8b9bab] focus:outline-none focus:border-[#64a7ff]"
								/>
							</div>
						</div>

						<div className="mb-4">
							<label
								htmlFor={passwordId}
								className="block text-[#cad5e2] text-sm mb-2"
							>
								Password
							</label>
							<div className="relative">
								<Lock className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-[#8b9bab]" />
								<input
									id={passwordId}
									type="password"
									value={password}
									onChange={(e) => setPassword(e.target.value)}
									placeholder="Enter your password"
									required
									className="w-full bg-[rgba(37,51,71,0.3)] border border-[#45556c] rounded-lg pl-10 pr-3 py-2.5 text-white placeholder-[#8b9bab] focus:outline-none focus:border-[#64a7ff]"
								/>
							</div>
						</div>

						{isSignup && (
							<div className="mb-6">
								<label
									htmlFor={confirmPasswordId}
									className="block text-[#cad5e2] text-sm mb-2"
								>
									Confirm Password
								</label>
								<div className="relative">
									<Lock className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-[#8b9bab]" />
									<input
										id={confirmPasswordId}
										type="password"
										value={confirmPassword}
										onChange={(e) => setConfirmPassword(e.target.value)}
										placeholder="Confirm your password"
										required
										className="w-full bg-[rgba(37,51,71,0.3)] border border-[#45556c] rounded-lg pl-10 pr-3 py-2.5 text-white placeholder-[#8b9bab] focus:outline-none focus:border-[#64a7ff]"
									/>
								</div>
							</div>
						)}

						<button
							type="submit"
							disabled={loading}
							className="w-full bg-[#64a7ff] hover:bg-[#5596ee] disabled:bg-[#45556c] disabled:cursor-not-allowed text-black font-medium py-2.5 rounded-lg transition-colors"
						>
							{loading
								? "Please wait..."
								: isSignup
									? "Create Admin Account"
									: "Sign In"}
						</button>
					</form>

					{hasAdmin && (
						<div className="mt-4 text-center">
							<button
								type="button"
								onClick={() => setIsSignup(!isSignup)}
								className="text-[#64a7ff] hover:text-[#5596ee] text-sm transition-colors"
							>
								{isSignup
									? "Already have an account? Sign in"
									: "Need to create first admin?"}
							</button>
						</div>
					)}
				</div>

				<p className="text-center text-[#8b9bab] text-sm mt-6">
					QuizMaster Admin Dashboard v1.0.0
				</p>
			</div>
		</div>
	);
}
