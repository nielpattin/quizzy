import { Link, useRouterState } from "@tanstack/react-router";
import {
	BarChart3,
	FileText,
	LayoutDashboard,
	Menu,
	MessageSquare,
	Trophy,
	Users,
} from "lucide-react";

const navItems = [
	{ path: "/admin", label: "Dashboard", icon: LayoutDashboard },
	{ path: "/admin/quiz-manager", label: "Quiz Manager", icon: FileText },
	{ path: "/admin/users", label: "Users", icon: Users },
	{ path: "/admin/contests", label: "Contests", icon: Trophy },
	{ path: "/admin/leaderboard", label: "Leaderboard", icon: BarChart3 },
	{ path: "/admin/feed-manager", label: "Feed Manager", icon: MessageSquare },
];

export function Sidebar() {
	const router = useRouterState();
	const currentPath = router.location.pathname;

	return (
		<div className="bg-[#1a2433] flex flex-col gap-4 h-screen w-72 fixed left-0 top-0">
			{/* Logo Section */}
			<div className="flex items-center justify-between px-6 py-6">
				<div className="flex gap-3 items-center">
					<div className="bg-[#64a7ff] rounded-2xl shadow-lg size-10 flex items-center justify-center">
						<Menu className="size-6 text-black" />
					</div>
					<div className="flex flex-col gap-0.5">
						<p className="text-white font-bold text-xl">QuizMaster</p>
						<p className="text-[#8b9bab] text-xs">Admin Panel</p>
					</div>
				</div>
			</div>

			{/* Navigation */}
			<nav className="flex flex-col gap-2.5 px-4">
				{navItems.map((item) => {
					const isActive = currentPath === item.path;
					const Icon = item.icon;

					return (
						<Link
							key={item.path}
							to={item.path}
							className={`flex gap-3 items-center pl-3 h-15 rounded-2xl transition-colors ${
								isActive
									? "bg-[#64a7ff] text-black"
									: "text-[#8b9bab] hover:bg-[#253347]"
							}`}
						>
							<div
								className={`rounded-xl size-9 flex items-center justify-center ${
									isActive ? "bg-white/20" : ""
								}`}
							>
								<Icon className="size-5" />
							</div>
							<span className="text-base font-normal">{item.label}</span>
						</Link>
					);
				})}
			</nav>
		</div>
	);
}
