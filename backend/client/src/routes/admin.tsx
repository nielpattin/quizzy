import { createFileRoute, redirect } from "@tanstack/react-router";
import { supabase } from "../lib/supabase";
import { AdminLayout } from "../layouts/AdminLayout";

export const Route = createFileRoute("/admin")({
	beforeLoad: async () => {
		const {
			data: { session },
		} = await supabase.auth.getSession();

		// Simple check: if no session exists, redirect to login
		// Session validation happens in AuthContext
		if (!session) {
			throw redirect({
				to: "/login",
				replace: true,
			});
		}
	},
	component: AdminLayout,
});
