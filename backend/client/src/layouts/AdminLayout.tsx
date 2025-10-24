import { Outlet } from "@tanstack/react-router";
import { Sidebar } from "../components/admin/Sidebar";

export function AdminLayout() {
	return (
		<div className="bg-[#0a0f1a] min-h-screen">
			<Sidebar />
			<main className="ml-72 p-6">
				<Outlet />
			</main>
		</div>
	);
}
