import { createFileRoute } from "@tanstack/react-router";
import { AdminLayout } from "../layouts/AdminLayout";

export const Route = createFileRoute("/admin")({
	component: AdminLayoutComponent,
});

function AdminLayoutComponent() {
	return <AdminLayout />;
}
