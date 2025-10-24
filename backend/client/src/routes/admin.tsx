import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect } from "react";
import { useAuth } from "../contexts/AuthContext";
import { AdminLayout } from "../layouts/AdminLayout";

export const Route = createFileRoute("/admin")({
	component: AdminLayoutComponent,
});

function AdminLayoutComponent() {
	const { session, loading } = useAuth();
	const navigate = useNavigate();

	useEffect(() => {
		if (!loading && !session) {
			navigate({ to: "/login" });
		}
	}, [session, loading, navigate]);

	if (loading) {
		return (
			<div className="min-h-screen bg-[#0a0f1a] flex items-center justify-center">
				<div className="text-white text-lg">Loading...</div>
			</div>
		);
	}

	if (!session) {
		return null;
	}

	return <AdminLayout />;
}
