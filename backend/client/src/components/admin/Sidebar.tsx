import { Link, useNavigate, useRouterState } from "@tanstack/react-router";
import {
	BarChart3,
	FileText,
	LayoutDashboard,
	LogOut,
	Menu,
	MessageSquare,
	Trophy,
	Users,
	ScrollText,
} from "lucide-react";
import { useAuth } from "../../contexts/AuthContext";

const navItems = [
	{ path: "/admin", label: "Dashboard", icon: LayoutDashboard },
	{ path: "/admin/quiz-manager", label: "Quiz Manager", icon: FileText },
	{ path: "/admin/users", label: "Users", icon: Users },
	{ path: "/admin/contests", label: "Contests", icon: Trophy },
	{ path: "/admin/leaderboard", label: "Leaderboard", icon: BarChart3 },
	{ path: "/admin/feed-manager", label: "Feed Manager", icon: MessageSquare },
	{ path: "/admin/logs", label: "Logs", icon: ScrollText },
];

export function Sidebar() {
	const router = useRouterState();
	const currentPath = router.location.pathname;
	const { user, signOut } = useAuth();
	const navigate = useNavigate();

	const handleLogout = async () => {
		await signOut();
		navigate({ to: "/login" });
	};

	const getInitials = (email: string | undefined) => {
		if (!email) return "?";
		return email
			.split("@")[0]
			.split(/[._-]/)
			.map((part) => part[0])
			.join("")
			.toUpperCase()
			.slice(0, 2);
	};

	return (
		<div className="bg-[#1a2433] flex flex-col h-screen w-72 fixed left-0 top-0">
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
			<nav className="flex flex-col gap-2.5 px-4 flex-1">
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

			{/* User Info & Logout */}
			<div className="px-4 pb-6 mt-auto">
				{/* User Info Card */}
				<div className="bg-[#253347] rounded-2xl p-3 mb-3">
					<div className="flex items-center gap-3">
						<div className="size-10 rounded-full bg-[#64a7ff] flex items-center justify-center flex-shrink-0">
							<span className="text-white font-bold text-sm">
								{getInitials(user?.email)}
							</span>
						</div>
						<div className="flex flex-col overflow-hidden">
							<p className="text-white text-sm font-medium truncate">
								{user?.email?.split("@")[0] || "User"}
							</p>
							<p className="text-[#8b9bab] text-xs">Admin</p>
						</div>
					</div>
				</div>

				{/* Logout Button */}
				<button
					type="button"
					onClick={handleLogout}
					className="w-full bg-[#253347] hover:bg-[#e7000b] text-[#8b9bab] hover:text-white px-4 py-3 rounded-2xl flex items-center gap-3 transition-colors"
				>
					<LogOut className="size-5" />
					<span className="text-base font-normal">Logout</span>
				</button>
			</div>
		</div>
	);
}
