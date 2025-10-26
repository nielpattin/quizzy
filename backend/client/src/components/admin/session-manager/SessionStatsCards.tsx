import { useQuery } from "@tanstack/react-query";
import { Activity, CheckCircle, Clock, Users } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { API_BASE_URL } from "@/lib/constants";

interface SessionStats {
	totalSessions: number;
	activeSessions: number;
	completedSessions: number;
	totalParticipants: number;
	avgDuration: number;
}

async function fetchSessionStats(token: string): Promise<SessionStats> {
	const response = await fetch(`${API_BASE_URL}/api/admin/sessions/stats`, {
		headers: {
			Authorization: `Bearer ${token}`,
		},
	});

	if (!response.ok) {
		throw new Error("Failed to fetch session stats");
	}

	return response.json();
}

interface StatCardProps {
	label: string;
	value: string | number;
	growth?: string;
	icon: React.ReactNode;
	iconBg: string;
}

function StatCard({ label, value, growth, icon, iconBg }: StatCardProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px]">
			<div className="flex items-center justify-between">
				<div className="space-y-1">
					<div className="text-[#8b9bab] text-[14px] leading-5">{label}</div>
					<div className="text-white text-[24px] font-bold leading-8">
						{value}
					</div>
					{growth && (
						<div className="text-[#05df72] text-[14px] leading-5">{growth}</div>
					)}
				</div>
				<div
					className={`${iconBg} rounded-[14px] w-[48px] h-[48px] flex items-center justify-center`}
				>
					{icon}
				</div>
			</div>
		</div>
	);
}

export function SessionStatsCards() {
	const { session } = useAuth();
	const token = session?.access_token;

	const { data: stats, isLoading } = useQuery({
		queryKey: ["session-stats"],
		queryFn: () =>
			token ? fetchSessionStats(token) : Promise.reject("No token"),
		enabled: !!token,
	});

	if (isLoading) {
		const skeletons = ["active", "participants", "completed", "duration"];
		return (
			<div className="grid grid-cols-4 gap-6">
				{skeletons.map((stat) => (
					<div
						key={stat}
						className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px] h-[130px] animate-pulse"
					/>
				))}
			</div>
		);
	}

	return (
		<div className="grid grid-cols-4 gap-6">
			<StatCard
				label="Active Sessions"
				value={stats?.activeSessions || 0}
				icon={<Activity className="w-6 h-6 text-[#8b9bab]" />}
				iconBg="bg-[#253347]"
			/>
			<StatCard
				label="Total Participants"
				value={stats?.totalParticipants || 0}
				icon={<Users className="w-6 h-6 text-[#8b9bab]" />}
				iconBg="bg-[#253347]"
			/>
			<StatCard
				label="Completed Sessions"
				value={stats?.completedSessions || 0}
				icon={<CheckCircle className="w-6 h-6 text-[#8b9bab]" />}
				iconBg="bg-[#253347]"
			/>
			<StatCard
				label="Avg. Duration"
				value={`${stats?.avgDuration || 0} min`}
				icon={<Clock className="w-6 h-6 text-[#8b9bab]" />}
				iconBg="bg-[#253347]"
			/>
		</div>
	);
}
