import { useQuery } from "@tanstack/react-query";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import {
	ChevronDown,
	Plus,
	Search,
	TrendingUp,
	UserCheck,
	UserPlus,
	Users,
} from "lucide-react";
import { useEffect, useState } from "react";
import { StatsCard } from "../../components/admin/StatsCard";
import { UserActionsMenu } from "../../components/admin/UserActionsMenu";
import { useAuth } from "../../contexts/AuthContext";
import { AuthError, apiGet } from "../../lib/api-client";
import { API_BASE_URL } from "../../lib/constants";

export const Route = createFileRoute("/admin/users")({
	component: UsersPage,
});

interface User {
	id: string;
	email: string;
	fullName: string;
	username: string | null;
	profilePictureUrl: string | null;
	accountType: string;
	status: string;
	lastLoginAt: string | null;
	createdAt: string;
	quizCount: number;
	avgScore: number;
}

interface UserStats {
	totalUsers: number;
	activeUsers: number;
	newThisMonth: number;
	avgCompletion: number;
}

async function fetchUserStats(): Promise<UserStats> {
	return apiGet<UserStats>(`${API_BASE_URL}/api/admin/users/stats`);
}

async function fetchUsers(
	search: string,
	role: string,
	status: string,
): Promise<{ users: User[]; total: number }> {
	const params = new URLSearchParams();
	if (search) params.append("search", search);
	if (role) params.append("role", role);
	if (status) params.append("status", status);

	return apiGet<{ users: User[]; total: number }>(
		`${API_BASE_URL}/api/admin/users?${params}`,
	);
}

function UsersPage() {
	const { session } = useAuth();
	const navigate = useNavigate();
	const [searchQuery, setSearchQuery] = useState("");
	const [roleFilter, setRoleFilter] = useState("");
	const [statusFilter, setStatusFilter] = useState("");

	const {
		data: stats,
		error: statsError,
		isError: isStatsError,
	} = useQuery({
		queryKey: ["admin", "users", "stats"],
		queryFn: fetchUserStats,
		enabled: !!session,
		retry: false,
	});

	const {
		data: usersData,
		isLoading,
		error: usersError,
		isError: isUsersError,
	} = useQuery({
		queryKey: ["admin", "users", searchQuery, roleFilter, statusFilter],
		queryFn: () => fetchUsers(searchQuery, roleFilter, statusFilter),
		enabled: !!session,
		retry: false,
	});

	// Redirect to login on auth errors
	useEffect(() => {
		if (
			isStatsError &&
			statsError instanceof AuthError &&
			(statsError.status === 401 || statsError.status === 403)
		) {
			console.error("[AUTH ERROR] Redirecting to login:", statsError.message);
			navigate({ to: "/login" });
		}

		if (
			isUsersError &&
			usersError instanceof AuthError &&
			(usersError.status === 401 || usersError.status === 403)
		) {
			console.error("[AUTH ERROR] Redirecting to login:", usersError.message);
			navigate({ to: "/login" });
		}
	}, [isStatsError, statsError, isUsersError, usersError, navigate]);

	const users = usersData?.users || [];

	const getInitials = (name: string) => {
		return name
			.split(" ")
			.map((n) => n[0])
			.join("")
			.toUpperCase()
			.slice(0, 2);
	};

	const formatDate = (dateString: string) => {
		return new Date(dateString).toLocaleDateString("en-US", {
			year: "numeric",
			month: "2-digit",
			day: "2-digit",
		});
	};

	const formatRelativeTime = (dateString: string | null) => {
		if (!dateString) return "Never";

		const date = new Date(dateString);
		const now = new Date();
		const diffMs = now.getTime() - date.getTime();
		const diffMins = Math.floor(diffMs / 60000);
		const diffHours = Math.floor(diffMs / 3600000);
		const diffDays = Math.floor(diffMs / 86400000);
		const diffWeeks = Math.floor(diffMs / 604800000);

		if (diffMins < 60)
			return `${diffMins} ${diffMins === 1 ? "minute" : "minutes"} ago`;
		if (diffHours < 24)
			return `${diffHours} ${diffHours === 1 ? "hour" : "hours"} ago`;
		if (diffDays < 7)
			return `${diffDays} ${diffDays === 1 ? "day" : "days"} ago`;
		if (diffWeeks < 4)
			return `${diffWeeks} ${diffWeeks === 1 ? "week" : "weeks"} ago`;

		return formatDate(dateString);
	};

	const getRoleBadgeColor = (role: string) => {
		switch (role) {
			case "admin":
				return "bg-[#e7000b]";
			case "employee":
				return "bg-[#155dfc]";
			case "user":
				return "bg-[#00a63e]";
			default:
				return "bg-[#45556c]";
		}
	};

	const getStatusBadgeColor = (status: string) => {
		return status === "active" ? "bg-[#00a63e]" : "bg-[#45556c]";
	};

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center justify-between">
				<div>
					<h1 className="text-white text-3xl font-bold">User Management</h1>
					<p className="text-[#90a1b9] mt-1">
						Manage users, roles, and permissions.
					</p>
				</div>
				<button
					type="button"
					className="bg-[#64a7ff] hover:bg-[#5596ee] text-black px-4 py-2 rounded-lg flex items-center gap-2 transition-colors"
				>
					<Plus className="size-4" />
					Add User
				</button>
			</div>

			<div className="grid grid-cols-4 gap-6">
				<StatsCard
					title="Total Users"
					value={stats?.totalUsers.toLocaleString() || "0"}
					change="+12%"
					icon={Users}
				/>
				<StatsCard
					title="Active Users"
					value={stats?.activeUsers.toLocaleString() || "0"}
					change="+8%"
					icon={UserCheck}
				/>
				<StatsCard
					title="New This Month"
					value={stats?.newThisMonth.toLocaleString() || "0"}
					change="+24%"
					icon={UserPlus}
				/>
				<StatsCard
					title="Avg. Completion"
					value={`${stats?.avgCompletion || 0}%`}
					change="+5%"
					icon={TrendingUp}
				/>
			</div>

			<div className="bg-[#1d293d] border border-[#314158] rounded-2xl p-6">
				<div className="flex items-center gap-4 mb-6">
					<div className="relative flex-1 max-w-2xl">
						<Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-[#8b9bab]" />
						<input
							type="text"
							placeholder="Search users by name or email..."
							value={searchQuery}
							onChange={(e) => setSearchQuery(e.target.value)}
							className="w-full bg-[rgba(37,51,71,0.3)] border border-[#45556c] rounded-lg pl-10 pr-3 py-2 text-white placeholder-[#8b9bab] focus:outline-none focus:border-[#64a7ff]"
						/>
					</div>

					<div className="relative">
						<select
							value={roleFilter}
							onChange={(e) => setRoleFilter(e.target.value)}
							className="appearance-none bg-[rgba(37,51,71,0.3)] border border-[#45556c] rounded-lg px-3 py-2 pr-8 text-white focus:outline-none focus:border-[#64a7ff] cursor-pointer"
						>
							<option value="">All Roles</option>
							<option value="admin">Admin</option>
							<option value="employee">Employee</option>
							<option value="user">User</option>
						</select>
						<ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 size-4 text-white pointer-events-none" />
					</div>

					<div className="relative">
						<select
							value={statusFilter}
							onChange={(e) => setStatusFilter(e.target.value)}
							className="appearance-none bg-[rgba(37,51,71,0.3)] border border-[#45556c] rounded-lg px-3 py-2 pr-8 text-white focus:outline-none focus:border-[#64a7ff] cursor-pointer"
						>
							<option value="">All Status</option>
							<option value="active">Active</option>
							<option value="inactive">Inactive</option>
						</select>
						<ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 size-4 text-white pointer-events-none" />
					</div>
				</div>

				<div className="bg-[#1d293d] border border-[#314158] rounded-2xl overflow-hidden">
					<div className="overflow-x-auto">
						<table className="w-full">
							<thead>
								<tr className="border-b border-[#314158]">
									<th className="text-left text-[#cad5e2] text-sm font-normal px-2 py-3">
										User
									</th>
									<th className="text-left text-[#cad5e2] text-sm font-normal px-2 py-3">
										Role
									</th>
									<th className="text-left text-[#cad5e2] text-sm font-normal px-2 py-3">
										Status
									</th>
									<th className="text-left text-[#cad5e2] text-sm font-normal px-2 py-3">
										Last Login
									</th>
									<th className="text-left text-[#cad5e2] text-sm font-normal px-2 py-3">
										Quizzes
									</th>
									<th className="text-left text-[#cad5e2] text-sm font-normal px-2 py-3">
										Avg Score
									</th>
									<th className="text-left text-[#cad5e2] text-sm font-normal px-2 py-3">
										Join Date
									</th>
									<th className="text-left text-[#cad5e2] text-sm font-normal px-2 py-3">
										{" "}
									</th>
								</tr>
							</thead>
							<tbody>
								{isLoading ? (
									<tr>
										<td colSpan={8} className="text-center py-8 text-[#8b9bab]">
											Loading users...
										</td>
									</tr>
								) : users.length === 0 ? (
									<tr>
										<td colSpan={8} className="text-center py-8 text-[#8b9bab]">
											No users found
										</td>
									</tr>
								) : (
									users.map((user) => (
										<tr key={user.id} className="border-b border-[#314158]">
											<td className="px-2 py-4">
												<div className="flex items-center gap-3">
													{user.profilePictureUrl ? (
														<img
															src={user.profilePictureUrl}
															alt={user.fullName}
															className="size-8 rounded-full"
														/>
													) : (
														<div className="size-8 rounded-full bg-[#155dfc] flex items-center justify-center">
															<span className="text-white text-sm">
																{getInitials(user.fullName)}
															</span>
														</div>
													)}
													<div className="flex flex-col">
														<span className="text-white text-sm">
															{user.fullName}
														</span>
														<span className="text-[#90a1b9] text-sm">
															{user.email}
														</span>
													</div>
												</div>
											</td>
											<td className="px-2 py-4">
												<span
													className={`${getRoleBadgeColor(user.accountType)} text-white text-xs px-2 py-1 rounded-lg capitalize`}
												>
													{user.accountType}
												</span>
											</td>
											<td className="px-2 py-4">
												<span
													className={`${getStatusBadgeColor(user.status)} text-white text-xs px-2 py-1 rounded-lg capitalize`}
												>
													{user.status}
												</span>
											</td>
											<td className="px-2 py-4 text-[#cad5e2] text-sm">
												{formatRelativeTime(user.lastLoginAt)}
											</td>
											<td className="px-2 py-4 text-[#cad5e2] text-sm">
												{user.quizCount}
											</td>
											<td className="px-2 py-4 text-[#cad5e2] text-sm">
												{Number(user.avgScore || 0).toFixed(1)}%
											</td>
											<td className="px-2 py-4 text-[#cad5e2] text-sm">
												{formatDate(user.createdAt)}
											</td>
											<td className="px-2 py-4">
												<UserActionsMenu
													userId={user.id}
													onEdit={(id) => console.log("Edit user:", id)}
													onDelete={(id) => console.log("Delete user:", id)}
													onChangeRole={(id) => console.log("Change role:", id)}
												/>
											</td>
										</tr>
									))
								)}
							</tbody>
						</table>
					</div>

					{users.length > 0 && (
						<div className="px-6 py-4 border-t border-[#314158] flex items-center justify-between">
							<p className="text-[#8b9bab] text-sm">
								Showing {users.length} of {usersData?.total || 0} users
							</p>
						</div>
					)}
				</div>
			</div>
		</div>
	);
}
